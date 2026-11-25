"""Construct a complete, commit-pinned source index from runner mirrors."""
from __future__ import annotations
from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import subprocess


def snapshot(manager, run_id, run_attempt, workflow_sha):
    def repository_index(source):
        name = str(source['repo'])
        mirror = manager.QUELLEN_DIR / (name + '.git')

        def git(*args):
            return subprocess.run(['git', '-C', str(mirror), *args], check=True,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=1800).stdout

        refs = git('for-each-ref', '--format=%(refname:strip=2)%00%(objectname)', 'refs/heads').splitlines()
        selected = []
        for line in refs:
            branch_bytes, commit = line.split(b'\0', 1)
            branch = os.fsdecode(branch_bytes)
            if source['branches'] == 'alle' or branch in source['branches']:
                selected.append((branch, commit.decode('ascii')))

        def branch_index(item):
            branch, commit = item
            paths = []
            for entry in git('ls-tree', '-r', '-z', '--full-tree', commit).split(b'\0'):
                if entry:
                    meta, path = entry.split(b'\t', 1)
                    text = os.fsdecode(path)
                    if meta.split(b' ')[1] == b'blob' and Path(text).suffix.lower() in manager.QUELLSPRACHEN:
                        paths.append(text)
            return branch, {'commit': commit, 'paths': paths}

        with ThreadPoolExecutor(max_workers=2) as pool:
            branches = dict(pool.map(branch_index, selected))
        if not branches or (source['branches'] != 'alle' and set(branches) != set(source['branches'])):
            raise ValueError('incomplete source branches')
        return name, branches

    with ThreadPoolExecutor(max_workers=3) as pool:
        repositories = dict(pool.map(repository_index, manager.QUELLEN))
    return {'version': 1, 'run_id': run_id, 'run_attempt': run_attempt,
            'workflow_sha': workflow_sha, 'repositories': repositories}
