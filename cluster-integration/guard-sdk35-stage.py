"""Free-disk-space monitor with external stage heartbeat."""
import json, os, sys, time
from pathlib import Path
from sdk35_process import Abort, run_group
abort = Abort(); abort.install()
status = os.environ.get('SDK35_STAGE_STATUS')
def publish(state, **fields):
    if status:
        path = Path(status); temporary = path.with_suffix('.tmp')
        temporary.write_text(json.dumps({'state':state, 'heartbeat':time.time(), **fields}))
        temporary.replace(path)
def check():
    disk = os.statvfs('/runtime-build')
    if disk.f_bavail * disk.f_frsize < 40 * 1024**3: raise RuntimeError('disk-space')
try:
    publish('starting')
    result = run_group(sys.argv[1:], abort, check, grace=20,
        tick=lambda p: publish('running', stage_pid=p.pid))
    if result < 0: result = 128 - result
    publish('finished', stage_exit=result)
except RuntimeError as error:
    publish('aborted', reason=str(error), stage_exit=75); result=75
except InterruptedError as error:
    result=128+abort.signal; publish('aborted', reason=str(error), stage_exit=result)
except BaseException as error:
    publish('failed', reason=repr(error), stage_exit=1); raise
sys.exit(result)
