"""Fetch pinned source repositories with a free-space stop gate."""
import json
import os
import pathlib
import signal
import subprocess
import sys
import time
from sdk35_process import Abort, run_group
abort = Abort()
abort.install()

ROOT = pathlib.Path('/runtime-build')
SOURCE = ROOT / 'aosp'
SOURCE.mkdir(exist_ok=True)
LOCK = json.loads((ROOT / 'contract/coherent-source-lock.json').read_text())
from sdk35_source_locks import load_locked_projects
PROJECTS = load_locked_projects(ROOT)
LIMIT = 40 * 1024**3

def check_space():
    state = os.statvfs(ROOT)
    if state.f_bavail * state.f_frsize < LIMIT:
        raise RuntimeError('STOP: less than 40 GiB free; all intermediate files retained')

def run(argv):
    result = run_group(argv, abort, check_space, grace=5)
    if result:
        raise subprocess.CalledProcessError(result, argv)

requested = sys.argv[1:] or ['frameworks/base', 'build/soong', 'build/blueprint']
for path in requested:
    project = PROJECTS[path]
    destination = SOURCE / path
    destination.mkdir(parents=True, exist_ok=True)
    prefix = ['git', '-C', str(destination)]
    if not (destination / '.git').exists():
        run(prefix + ['init', '-q'])
        run(prefix + ['remote', 'add', 'origin',
            'https://android.googlesource.com/' + project['name']])
    exists = subprocess.run(prefix + ['cat-file', '-e', project['revision']],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if not exists:
        run(prefix + ['-c', 'http.version=HTTP/1.1', 'fetch', '--depth=1',
                      'origin', project['revision']])
    current = subprocess.run(prefix + ['rev-parse', '--verify', 'HEAD'],
                             capture_output=True, text=True)
    if current.returncode or current.stdout.strip() != project['revision']:
        # Never overwrite local porting patches or an unexpected source revision.
        dirty = subprocess.check_output(prefix + ['status', '--porcelain'], text=True)
        if dirty:
            raise RuntimeError('Refusing checkout over source edits: ' + path)
        run(prefix + ['checkout', '--detach', project['revision']])
    print('PINNED', path, project['revision'], flush=True)
check_space()
