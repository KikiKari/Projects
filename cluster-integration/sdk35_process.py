"""Bounded POSIX group cleanup. Group existence includes zombies."""
import os, signal, subprocess, time
class Abort:
    def __init__(self): self.signal = None
    def request(self, number, frame):
        if self.signal is None: self.signal = number
    def install(self):
        for number in (signal.SIGINT, signal.SIGTERM): signal.signal(number, self.request)
def group_exists(pgid):
    try: os.killpg(pgid, 0); return True
    except ProcessLookupError: return False
    except PermissionError:
        print(f'ERROR: permission denied checking group {pgid}', flush=True); raise
def send_group(pgid, number):
    try: os.killpg(pgid, number)
    except ProcessLookupError: pass
    except PermissionError:
        print(f'ERROR: permission denied signaling group {pgid}', flush=True); raise
def cleanup(process, grace):
    pgid = process.pid
    deadline = time.monotonic() + grace
    send_group(pgid, signal.SIGTERM)
    while time.monotonic() < deadline:
        process.poll()
        if not group_exists(pgid): break
        time.sleep(min(0.05, max(0, deadline-time.monotonic())))
    if group_exists(pgid):
        print(f'ESCALATE: SIGKILL group {pgid}', flush=True)
        send_group(pgid, signal.SIGKILL)
    process.wait(timeout=2)
    print(f'CLEANUP: pgid={pgid} leader_exit={process.returncode} group_present={group_exists(pgid)}', flush=True)
def run_group(argv, abort, check, grace=5, tick=None):
    check()
    if abort.signal is not None: raise InterruptedError(f'signal {abort.signal}')
    process = subprocess.Popen(argv, start_new_session=True)
    try:
        while True:
            if abort.signal is not None: raise InterruptedError(f'signal {abort.signal}')
            check()
            if tick: tick(process)
            result = process.poll()
            if result is not None:
                if group_exists(process.pid): cleanup(process, grace)
                return result
            time.sleep(0.1)
    except BaseException:
        cleanup(process, grace)
        raise
