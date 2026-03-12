#!/usr/bin/env python3
"""
Benboerba Restore - restore from benboerba git repo to ~/.openclaw/.

The repo mirrors ~/.openclaw/ structure:
  repo/workspace/AGENTS.md         →  <root>/workspace/AGENTS.md
  repo/openclaw.json.age           →  <root>/openclaw.json
  repo/workspace-fin.tar.gz.age    →  <root>/workspace-fin/

Usage:
    python3 restore.py [--repo <path>] [--restore-root <path>] [--age-key <path>] [--dry-run] [--confirm]
"""
import argparse, json, os, shutil, subprocess, sys, tarfile, tempfile
from pathlib import Path

HOME = Path.home()
DEFAULT_REPO = HOME / 'workspace' / 'benboerba'
DEFAULT_ROOT = HOME / '.openclaw'
DEFAULT_KEY = HOME / '.openclaw' / 'age.key'


def decrypt_file(src: Path, dst: Path, key_file: Path):
    dst.parent.mkdir(parents=True, exist_ok=True)
    with open(src, 'rb') as fin, open(dst, 'wb') as fout:
        r = subprocess.run(['age', '-d', '-i', str(key_file)], stdin=fin, stdout=fout)
        if r.returncode != 0:
            raise RuntimeError(f'age decrypt failed: {src}')


def restore(args):
    repo = Path(os.path.expanduser(args.repo)).resolve()
    restore_root = Path(os.path.expanduser(args.restore_root)).resolve()
    key_file = Path(os.path.expanduser(args.age_key)).resolve()

    # Pull latest if it's a git repo
    if (repo / '.git').exists():
        print(f'📥 Pulling latest from {repo}...')
        subprocess.run(['git', 'pull'], cwd=repo, check=False)
    elif repo.exists():
        pass
    else:
        # Try clone
        print(f'🌀 Cloning {args.repo}...')
        subprocess.run(['git', 'clone', args.repo, str(repo)], check=True)

    # Load meta
    meta_path = repo / 'meta.json'
    if not meta_path.exists():
        print('❌ meta.json not found in repo')
        sys.exit(1)

    meta = json.loads(meta_path.read_text())
    files = meta.get('files', [])
    print(f'📋 Backup from: {meta.get("createdAt", "unknown")}')
    print(f'📁 Restore root: {restore_root}')
    print(f'📦 Entries: {len(files)}')

    # Plan restore actions
    actions = []
    for entry in files:
        stored_path = entry['path']
        is_private = entry.get('private', False)
        is_dir = entry.get('type') == 'dir'
        original_path = entry.get('originalPath', stored_path)

        src = repo / stored_path
        if not src.exists():
            print(f'  ⚠️  missing in repo: {stored_path}')
            continue

        if is_private:
            dst = restore_root / original_path
            if is_dir:
                # .tar.gz.age → decrypt → untar
                actions.append(('decrypt-untar', src, dst, original_path))
            else:
                # .age → decrypt
                actions.append(('decrypt', src, dst, original_path))
        else:
            dst = restore_root / stored_path
            if is_dir:
                actions.append(('copy-dir', src, dst, stored_path))
            else:
                actions.append(('copy-file', src, dst, stored_path))

    # Show plan
    print(f'\n📋 Restore plan ({len(actions)} actions):')
    for kind, src, dst, label in actions:
        icon = '🔐' if kind.startswith('decrypt') else '📄'
        print(f'  {icon} [{kind}] {label} → {dst}')

    if args.dry_run:
        print(f'\n🔍 [DRY-RUN] Would restore {len(actions)} items. No changes made.')
        return

    if not args.confirm:
        print('\n⚠️  Use --confirm to execute restore (destructive operation).')
        return

    if any(a[0].startswith('decrypt') for a in actions):
        if not key_file.exists():
            print(f'❌ age key not found: {key_file}')
            sys.exit(1)

    # Execute
    print('\n🔄 Restoring...')
    for kind, src, dst, label in actions:
        try:
            if kind == 'copy-file':
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
                print(f'  ✓ {label}')

            elif kind == 'copy-dir':
                if dst.exists():
                    shutil.rmtree(dst)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copytree(src, dst, symlinks=True)
                print(f'  ✓ {label}/')

            elif kind == 'decrypt':
                with tempfile.NamedTemporaryFile(delete=False) as tmp:
                    tmp_path = Path(tmp.name)
                try:
                    decrypt_file(src, tmp_path, key_file)
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(tmp_path, dst)
                    print(f'  🔐 {label}')
                finally:
                    tmp_path.unlink(missing_ok=True)

            elif kind == 'decrypt-untar':
                with tempfile.TemporaryDirectory() as td:
                    td = Path(td)
                    decrypted_tar = td / 'decrypted.tar.gz'
                    decrypt_file(src, decrypted_tar, key_file)
                    # Extract - the tar contains <dirname>/ at top level
                    with tarfile.open(decrypted_tar, 'r:gz') as tar:
                        tar.extractall(td / 'unpacked')
                    # The unpacked dir should have one top-level entry matching the dir name
                    unpacked = td / 'unpacked'
                    entries = list(unpacked.iterdir())
                    if len(entries) == 1 and entries[0].is_dir():
                        src_dir = entries[0]
                    else:
                        src_dir = unpacked
                    if dst.exists():
                        shutil.rmtree(dst)
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copytree(src_dir, dst, symlinks=True)
                    print(f'  🔐 {label}/')

        except Exception as e:
            print(f'  ❌ {label}: {e}')

    print(f'\n✅ Restore complete! ({len(actions)} items → {restore_root})')


def main():
    ap = argparse.ArgumentParser(description='Benboerba Restore')
    ap.add_argument('--repo', default=str(DEFAULT_REPO),
                    help='Git repo URL or local path (default: ~/workspace/benboerba)')
    ap.add_argument('--restore-root', default=str(DEFAULT_ROOT),
                    help='Restore target root (default: ~/.openclaw/)')
    ap.add_argument('--age-key', default=str(DEFAULT_KEY),
                    help='Path to age private key')
    ap.add_argument('--dry-run', action='store_true',
                    help='Preview restore plan without executing')
    ap.add_argument('--confirm', action='store_true',
                    help='Actually execute restore (required)')
    args = ap.parse_args()
    restore(args)


if __name__ == '__main__':
    main()
