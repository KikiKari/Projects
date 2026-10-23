"""Host-only disk preflight; never creates or controls a container."""
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys
import uuid

LIMIT = 42949672960


def measure(path):
    result = subprocess.run(
        ['df', '--output=avail', '-B1', str(path)],
        capture_output=True, text=True, timeout=10, check=True)
    lines = result.stdout.strip().splitlines()
    if len(lines) != 2 or not re.fullmatch(r'[0-9]+', lines[1].strip()):
        raise ValueError('Invalid df available-byte measurement: ' + repr(result.stdout))
    return int(lines[1].strip())


def write_report(root, report):
    directory = root / 'contract' / report['run_id']
    directory.mkdir(parents=True, exist_ok=False)
    target = directory / 'preflight-result.json'
    temporary = directory / 'preflight-result.tmp'
    temporary.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    temporary.replace(target)
    return target


def preflight(root, stage, measurement=measure, writer=write_report):
    root = Path(root).resolve()
    timestamp = datetime.now(timezone.utc).isoformat()
    run_id = 'preflight-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex
    available = None
    error = None
    try:
        available = measurement(root)
        if type(available) is not int or available < 0:
            raise ValueError('Available bytes must be a nonnegative integer')
    except Exception as exception:
        available = None
        error = repr(exception)
    if error is None and available >= LIMIT:
        return 0
    code = 125 if error is not None else 75
    report = {
        'run_id': run_id, 'stage': stage, 'timestamp': timestamp,
        'check_path': str(root), 'available_bytes': available, 'threshold_bytes': LIMIT,
        'abort_reason': 'disk_space_measurement_failed' if error else 'insufficient_disk_space',
        'measurement_error': error, 'wrapper_exit_code': code,
        'container_id': None, 'container_exit_code': None,
        'container_created': False, 'cleanup_required': False,
    }
    try:
        target = writer(root, report)
    except Exception as exception:
        print('ERROR: preflight report not saved: ' + repr(exception), file=sys.stderr, flush=True)
        print(json.dumps(report), file=sys.stderr, flush=True)
    else:
        print('PREFLIGHT EVIDENCE ' + str(target), file=sys.stderr, flush=True)
    return code


if __name__ == '__main__':
    sys.exit(preflight(Path.cwd(), sys.argv[1] if len(sys.argv) > 1 else None))
