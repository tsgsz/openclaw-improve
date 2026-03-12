#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""demo_em_fetch.py

最小可运行示例：从东方财富 push2 拉取个股 JSON，并做简单估值筛选。

注意：
- 东方财富字段（fxxx）可能变化；本脚本尽量保留原始 data 字段以便人工核对。
- 本脚本仅做信息整理，不构成投资建议。

用法：
  python skills/a-share-undervaluation/demo_em_fetch.py --codes 600519,000001 --pb-max 1.5 --pe-max 15

"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import time
import urllib.parse
import urllib.request


UT = "fa5fd1943c7b386f172d6893dbfba10b"  # 常见公开参数；若失效需更新

# 经验映射：并非官方文档，可能失准。若字段缺失，脚本会跳过筛选并提示。
FIELDS = [
    "f57",  # code
    "f58",  # name
    "f43",  # last price
    "f59",  # pct change?
    "f116",  # market cap?
    "f162",  # pe_ttm?
    "f167",  # pb?
    "f46",  # open?
    "f60",  # prev close?
]


def now_cn_str() -> str:
    # 本地机器时区由运行环境决定；这里按 Asia/Shanghai 文案输出
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M")


def guess_secid(code: str) -> str:
    code = code.strip()
    if not code.isdigit() or len(code) != 6:
        raise ValueError(f"bad code: {code}")
    if code.startswith("6"):
        mkt = "1"  # SH
    elif code.startswith(("0", "3")):
        mkt = "0"  # SZ
    elif code.startswith(("8", "4")):
        # 北交所/新三板在东财体系可能不同；这里先按 0 试探，失败再让用户手动传 secid
        mkt = "0"
    else:
        mkt = "0"
    return f"{mkt}.{code}"


def http_get_json(url: str, timeout: int = 10) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0",
            "Accept": "application/json,text/plain,*/*",
        },
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode("utf-8", errors="replace")
    return json.loads(raw)


def fetch_em_stock(code_or_secid: str) -> dict:
    if "." in code_or_secid:
        secid = code_or_secid
    else:
        secid = guess_secid(code_or_secid)

    params = {
        "ut": UT,
        "fltt": "2",
        "invt": "2",
        "secid": secid,
        "fields": ",".join(FIELDS),
    }
    url = "https://push2.eastmoney.com/api/qt/stock/get?" + urllib.parse.urlencode(params)
    j = http_get_json(url)
    return {
        "_req": {"secid": secid, "url": url},
        "raw": j,
        "data": (j or {}).get("data") or {},
    }


def to_float(x):
    try:
        if x in (None, "-", ""):
            return None
        return float(x)
    except Exception:
        return None


def pick(d: dict, key: str):
    return d.get(key)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--codes", required=True, help="逗号分隔代码，如 600519,000001；也可传 secid 如 1.600519")
    ap.add_argument("--pb-max", type=float, default=None)
    ap.add_argument("--pe-max", type=float, default=None)
    ap.add_argument("--sleep", type=float, default=0.3, help="请求间隔（秒），避免触发限流")
    args = ap.parse_args(argv)

    codes = [c.strip() for c in args.codes.split(",") if c.strip()]

    print(f"【a-share-undervaluation | MVP】数据更新时间：{now_cn_str()}（Asia/Shanghai）")
    print("数据源：东方财富 push2（字段为经验映射，需人工校验；不构成投资建议）")

    results = []
    for c in codes:
        try:
            item = fetch_em_stock(c)
        except Exception as e:
            print(f"- {c}: 拉取失败：{e}")
            continue

        data = item["data"]
        code = pick(data, "f57") or c
        name = pick(data, "f58") or "(unknown)"

        pb = to_float(pick(data, "f167"))
        pe = to_float(pick(data, "f162"))

        ok = True
        reasons = []
        if args.pb_max is not None:
            if pb is None:
                ok = False
                reasons.append("PB缺失")
            elif pb > args.pb_max:
                ok = False
                reasons.append(f"PB {pb:.2f} > {args.pb_max}")

        if args.pe_max is not None:
            if pe is None:
                ok = False
                reasons.append("PE(TTM)缺失")
            elif pe > args.pe_max:
                ok = False
                reasons.append(f"PE(TTM) {pe:.2f} > {args.pe_max}")

        results.append({
            "code": code,
            "name": name,
            "pb": pb,
            "pe_ttm": pe,
            "ok": ok,
            "reasons": reasons,
            "req": item["_req"],
            "data": data,
        })

        time.sleep(args.sleep)

    print("\n【候选】")
    for r in results:
        if not r["ok"]:
            continue
        pb_s = "-" if r["pb"] is None else f"{r['pb']:.2f}"
        pe_s = "-" if r["pe_ttm"] is None else f"{r['pe_ttm']:.2f}"
        print(f"- {r['code']} {r['name']} | PB {pb_s} | PE(TTM) {pe_s}")

    print("\n【未通过/缺失】")
    for r in results:
        if r["ok"]:
            continue
        reason = "; ".join(r["reasons"]) if r["reasons"] else "不满足条件"
        print(f"- {r['code']} {r['name']}: {reason}")

    print("\n【调试：请求与原始字段快照（用于口径校验）】")
    for r in results:
        print(f"- {r['code']} req: {r['req']['url']}")
        # 只打印 data，避免太长
        print("  data:", json.dumps(r["data"], ensure_ascii=False))

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
