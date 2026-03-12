#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""demo_sanity_check.py

离线 MVP：读取用户提供的关键财务/治理字段（CSV），输出红旗。

- 不联网
- 不引入重依赖（仅用标准库）
- 仅做风险识别与信息整理，不构成投资建议

用法：
  python skills/a-share-sanity-check/demo_sanity_check.py --csv data/sample_sanity_input.csv

说明：
- CSV 字段可能不全；缺失则跳过相关规则（真实使用时应在报告中标注[未核验]）。
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import sys
from dataclasses import dataclass


def now_cn_str() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M")


def f(x: str):
    try:
        if x is None:
            return None
        x = str(x).strip()
        if x in ("", "-", "None", "null"):
            return None
        return float(x)
    except Exception:
        return None


@dataclass
class Flags:
    red: list[str]
    yellow: list[str]


def add_ratio_flag(flags: Flags, name: str, val: float | None, y_thr: float, r_thr: float, fmt: str = "{:.0%}"):
    if val is None:
        return
    if val >= r_thr:
        flags.red.append(f"{name}高（{fmt.format(val)} ≥ {fmt.format(r_thr)}）")
    elif val >= y_thr:
        flags.yellow.append(f"{name}偏高（{fmt.format(val)} ≥ {fmt.format(y_thr)}）")


def ocf_np_ratio(np, ocf):
    if np is None or ocf is None or np == 0:
        return None
    return ocf / np


def yoy(curr, prev):
    if curr is None or prev is None or prev == 0:
        return None
    return (curr - prev) / abs(prev)


def sanity_check(row: dict) -> Flags:
    flags = Flags(red=[], yellow=[])

    # Base fields
    net_profit = f(row.get("net_profit"))
    net_profit_prev = f(row.get("net_profit_prev"))
    op_cf = f(row.get("op_cf"))
    op_cf_prev = f(row.get("op_cf_prev"))

    equity = f(row.get("equity"))
    goodwill = f(row.get("goodwill"))

    total_assets = f(row.get("total_assets"))
    total_liab = f(row.get("total_liab"))

    non_rec = f(row.get("non_recurring_profit"))
    pledge_ratio = f(row.get("pledge_ratio"))

    # Optional fields (extended rules)
    revenue = f(row.get("revenue"))
    revenue_prev = f(row.get("revenue_prev"))

    ar = f(row.get("ar"))
    ar_prev = f(row.get("ar_prev"))

    inventory = f(row.get("inventory"))
    inventory_prev = f(row.get("inventory_prev"))

    capex = f(row.get("capex"))
    fcf = f(row.get("fcf"))

    cash_div = f(row.get("cash_dividend"))
    cash_div_prev = f(row.get("cash_dividend_prev"))

    interest_expense = f(row.get("interest_expense"))
    ebit = f(row.get("ebit"))

    short_debt = f(row.get("short_debt"))
    cash = f(row.get("cash"))

    # 1) 连续亏损
    if net_profit is not None and net_profit_prev is not None:
        if net_profit < 0 and net_profit_prev < 0:
            flags.red.append("连续两年归母净利润为负")

    # 2) 现金流质量
    r1 = ocf_np_ratio(net_profit, op_cf)
    r0 = ocf_np_ratio(net_profit_prev, op_cf_prev)
    if r1 is not None and r0 is not None and (r1 < 0.8 and r0 < 0.8):
        flags.red.append("经营现金流/净利润连续两年偏低（<0.8）")

    if net_profit is not None and op_cf is not None and (net_profit > 0 and op_cf < 0):
        flags.red.append("净利润为正但经营现金流为负（可能存在回款/收入确认压力）")

    # 3) 商誉
    if goodwill is not None and equity not in (None, 0):
        g_ratio = goodwill / equity
        add_ratio_flag(flags, "商誉/净资产", g_ratio, y_thr=0.30, r_thr=0.50)

    # 4) 负债率
    if total_liab is not None and total_assets not in (None, 0):
        d_ratio = total_liab / total_assets
        add_ratio_flag(flags, "资产负债率", d_ratio, y_thr=0.70, r_thr=0.80)

    # 5) 非经常性损益依赖（简化：非经常性损益占净利润比例）
    if non_rec is not None and net_profit not in (None, 0):
        nr_ratio = abs(non_rec) / max(1e-9, abs(net_profit))
        if nr_ratio >= 0.5:
            flags.red.append("非经常性损益占比偏高（需核对扣非净利润）")
        elif nr_ratio >= 0.3:
            flags.yellow.append("存在一定非经常性损益影响（建议看扣非）")

    # 6) 质押
    add_ratio_flag(flags, "控股股东质押比例", pledge_ratio, y_thr=0.30, r_thr=0.50)

    # 7) 回款/应收：应收增长快于收入
    rev_yoy = yoy(revenue, revenue_prev)
    ar_yoy = yoy(ar, ar_prev)
    if rev_yoy is not None and ar_yoy is not None:
        if ar_yoy - rev_yoy >= 0.30:
            flags.red.append("应收增长显著快于收入（回款压力/放宽信用风险）")
        elif ar_yoy - rev_yoy >= 0.15:
            flags.yellow.append("应收增速快于收入（建议核验账期与坏账准备）")

    # 8) 库存：存货增长快于收入
    inv_yoy = yoy(inventory, inventory_prev)
    if rev_yoy is not None and inv_yoy is not None:
        if inv_yoy - rev_yoy >= 0.30:
            flags.red.append("存货增长显著快于收入（库存/跌价风险）")
        elif inv_yoy - rev_yoy >= 0.15:
            flags.yellow.append("存货增速快于收入（建议核验去化与减值）")

    # 9) CAPEX 与现金流覆盖
    if capex is not None and op_cf is not None:
        # capex 通常为负值（现金流量表），这里用绝对值比较
        if abs(capex) > 0 and op_cf < 0:
            flags.red.append("经营现金流为负且存在资本开支（现金流压力）")
        elif abs(capex) > op_cf and op_cf > 0:
            flags.yellow.append("资本开支可能超过经营现金流（需关注融资依赖）")

    if fcf is not None:
        if fcf < 0:
            flags.yellow.append("自由现金流为负（需关注资本开支与回款）")

    # 10) 分红与自由现金流
    if cash_div is not None and fcf is not None:
        if cash_div > 0 and fcf <= 0:
            flags.red.append("现金分红与自由现金流不匹配（分红可持续性存疑）")
        elif cash_div > 0 and fcf > 0 and cash_div / fcf >= 0.8:
            flags.yellow.append("分红占自由现金流比例偏高（留存不足风险）")

    # 11) 利息覆盖（若可得）
    if ebit is not None and interest_expense not in (None, 0):
        cov = ebit / abs(interest_expense)
        if cov < 2:
            flags.red.append("利息覆盖偏弱（EBIT/利息<2）")
        elif cov < 3:
            flags.yellow.append("利息覆盖一般（EBIT/利息<3）")

    # 12) 短债压力（若可得）
    if short_debt is not None and cash is not None and cash > 0:
        sd_ratio = short_debt / cash
        if sd_ratio >= 1.5:
            flags.red.append("短债/货币资金偏高（短期偿债压力）")
        elif sd_ratio >= 1.0:
            flags.yellow.append("短债/货币资金偏高（需关注再融资）")

    return flags


def summarize_level(flags: Flags) -> str:
    if len(flags.red) >= 2:
        return "高风险"
    if len(flags.red) == 1:
        return "待核验"
    if len(flags.yellow) >= 2:
        return "待核验"
    return "相对健康"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    args = ap.parse_args(argv)

    rows = []
    with open(args.csv, "r", encoding="utf-8") as f_in:
        reader = csv.DictReader(f_in)
        for r in reader:
            rows.append(r)

    print(f"【a-share-sanity-check | MVP】数据更新时间：{now_cn_str()}（Asia/Shanghai）")
    print("数据源：用户提供CSV/离线规则引擎（需自行核对原始财报/公告；不构成投资建议）")

    print("\n【逐只体检】")
    for r in rows:
        code = (r.get("code") or "").strip()
        name = (r.get("name") or "").strip() or "(unknown)"
        flags = sanity_check(r)
        level = summarize_level(flags)

        print(f"- {code} {name}｜{level}｜红旗{len(flags.red)} 黄旗{len(flags.yellow)}")
        for x in flags.red:
            print(f"  - 红旗：{x}")
        for x in flags.yellow:
            print(f"  - 黄旗：{x}")

    print("\n【风险提示】")
    print("- 规则命中不等于一定有问题：仅提示需要优先核验的方向。")
    print("- 行业差异很大（金融/地产/周期），阈值需按行业校准。")
    print("- 财务数据可能滞后或被重述，请以公告与定期报告为准。")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
