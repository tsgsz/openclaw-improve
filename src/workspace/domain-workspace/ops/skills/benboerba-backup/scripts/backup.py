#!/usr/bin/env python3
"""
Benboerba Backup - mirror ~/.openclaw/ to benboerba git repo.

Manifest entries are stored relative to ~/.openclaw/:
  ~/.openclaw/workspace/AGENTS.md  ->  repo/workspace/AGENTS.md
  ~/.openclaw/openclaw.json        ->  repo/openclaw.json.age (private)
  ~/.openclaw/workspace            ->  repo/workspace.tar.gz.age (private dir)
  ~/.openclaw/openclaw.json        ->  repo/openclaw.json.age (private)

Usage:
    python3 backup.py [--manifest <path>] [--push]
"""

import argparse, glob, json, os, shutil, subprocess, sys, tarfile, tempfile
from datetime import datetime
from pathlib import Path
from typing import Optional

HOME = Path.home()
OPENCLAW_ROOT = HOME / ".openclaw"
PROJECT = HOME / "workspace" / "benboerba-eternal"
BENBOERBA = HOME / "workspace" / "benboerba"
DEFAULT_MANIFEST = PROJECT / "manifest.json"


def rel_to_openclaw(p: Path) -> Optional[str]:
    """Return path relative to ~/.openclaw/, or None if outside."""
    try:
        return str(p.relative_to(OPENCLAW_ROOT))
    except ValueError:
        return None


def expand_entries(patterns: list[str]) -> list[Path]:
    """Expand manifest patterns (supports ~ and glob *)."""
    out = []
    for pat in patterns:
        expanded = os.path.expanduser(pat)
        matches = sorted(glob.glob(expanded))
        if not matches:
            print(f"  ! skip missing: {expanded}")
        for m in matches:
            p = Path(m).resolve()
            if p.exists():
                out.append(p)
    return out


def encrypt_file(src: Path, dst: Path, pubkey: str):
    dst.parent.mkdir(parents=True, exist_ok=True)
    with open(src, "rb") as fin, open(dst, "wb") as fout:
        r = subprocess.run(["age", "-r", pubkey], stdin=fin, stdout=fout)
        if r.returncode != 0:
            raise RuntimeError(f"age encrypt failed: {src}")


def copy_public(src: Path, dst: Path):
    """Copy file or directory to dst, preserving structure."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst, symlinks=True)
    else:
        shutil.copy2(src, dst)


def backup_private(src: Path, dst_base: Path, pubkey: str):
    """Encrypt a private entry. Files → .age, dirs → .tar.gz.age."""
    if src.is_dir():
        dst = dst_base.with_suffix(".tar.gz.age")
        dst.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as tmp:
            tmp_path = Path(tmp.name)
        try:
            with tarfile.open(tmp_path, "w:gz") as tar:
                tar.add(src, arcname=src.name)
            encrypt_file(tmp_path, dst, pubkey)
        finally:
            tmp_path.unlink(missing_ok=True)
    else:
        dst = dst_base.with_suffix(dst_base.suffix + ".age")
        encrypt_file(src, dst, pubkey)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    ap.add_argument("--push", action="store_true")
    args = ap.parse_args()

    manifest = json.loads(Path(args.manifest).read_text())
    pubkey_path = Path(
        os.path.expanduser(manifest.get("agePublicKeyFile", "~/.openclaw/age.pub"))
    )
    pubkey = pubkey_path.read_text().strip()

    pub_paths = expand_entries(manifest.get("public", []))
    pri_paths = expand_entries(manifest.get("private", []))

    # Clean repo working tree (keep .git)
    print("🧹 Cleaning benboerba repo...")
    for item in BENBOERBA.iterdir():
        if item.name == ".git":
            continue
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()

    # Copy public entries
    files_meta = []
    print("\n📄 Public files:")
    for src in pub_paths:
        rel = rel_to_openclaw(src)
        if rel is None:
            print(f"  ! skip (outside .openclaw): {src}")
            continue
        dst = BENBOERBA / rel
        copy_public(src, dst)
        files_meta.append(
            {"path": rel, "private": False, "type": "dir" if src.is_dir() else "file"}
        )
        print(f"  ✓ {rel}")

    # Encrypt private entries
    print("\n🔐 Private files:")
    for src in pri_paths:
        rel = rel_to_openclaw(src)
        if rel is None:
            print(f"  ! skip (outside .openclaw): {src}")
            continue
        dst_base = BENBOERBA / rel
        backup_private(src, dst_base, pubkey)
        suffix = ".tar.gz.age" if src.is_dir() else ".age"
        stored = (
            rel + (".tar.gz.age" if src.is_dir() else ".age")
            if not rel.endswith(".age")
            else rel
        )
        # Compute actual stored name
        if src.is_dir():
            stored_path = str(Path(rel).with_suffix(".tar.gz.age"))
        else:
            stored_path = rel + ".age"
        files_meta.append(
            {
                "path": stored_path,
                "private": True,
                "type": "dir" if src.is_dir() else "file",
                "originalPath": rel,
            }
        )
        print(f"  🔐 {stored_path}")

    # Write meta.json
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    meta = {
        "timestamp": ts,
        "createdAt": datetime.now().isoformat(),
        "openclaw_root": str(OPENCLAW_ROOT),
        "files": files_meta,
    }
    (BENBOERBA / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))
    print(f"\n📝 meta.json written ({len(files_meta)} entries)")

    # Git
    subprocess.run(["git", "add", "-A"], cwd=BENBOERBA, check=True)
    r = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=BENBOERBA)
    if r.returncode == 0:
        print("\n✅ No changes to commit.")
        return

    subprocess.run(
        ["git", "commit", "-m", f"backup snapshot {ts}"], cwd=BENBOERBA, check=True
    )
    print(f"\n✅ Committed: backup snapshot {ts}")

    if args.push:
        subprocess.run(["git", "push", "origin", "main"], cwd=BENBOERBA, check=True)
        print("✅ Pushed to GitHub.")


if __name__ == "__main__":
    main()
