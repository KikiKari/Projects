"""Construct a complete, commit-pinned source index from runner mirrors."""
from __future__ import annotations
import os
from pathlib import Path
import subprocess


def snapshot(manager, run_id, run_attempt, workflow_sha):
    repositories = {}
    for source in manager.QUELLEN:
        name = str(source['repo'])
        mirror = manager.QUELLEN_DIR / (name + '.git')
        def git(*args):
            return subprocess.run(['git', '-C', str(mirror), *args], check=True,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=1800).stdout
        refs = git('for-each-ref', '--format=%(refname:strip=2)%00%(objectname)', 'refs/heads').splitlines()
        branches = {}
        for line in refs:
            branch_bytes, commit = line.split(b'\0', 1)
            branch = os.fsdecode(branch_bytes)
            if source['branches'] != 'alle' and branch not in source['branches']:
                continue
            paths = []
            for entry in git('ls-tree', '-r', '-z', '--full-tree', commit.decode('ascii')).split(b'\0'):
                if entry:
                    meta, path = entry.split(b'\t', 1)
                    text = os.fsdecode(path)
                    if meta.split(b' ')[1] == b'blob' and Path(text).suffix.lower() in manager.QUELLSPRACHEN:
                        paths.append(text)
            branches[branch] = {'commit': commit.decode('ascii'), 'paths': paths}
        if not branches or (source['branches'] != 'alle' and set(branches) != set(source['branches'])):
            raise ValueError('incomplete source branches')
        repositories[name] = branches
    return {'version': 1, 'run_id': run_id, 'run_attempt': run_attempt,
            'workflow_sha': workflow_sha, 'repositories': repositories}
