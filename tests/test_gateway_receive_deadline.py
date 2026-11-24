import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import urllib.error

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'abstractions' / 'runtime'))
import runner_manager

class Clock:
    def __init__(self): self.now = 100.0
    def monotonic(self): return self.now
    def time(self): return 1000 + self.now
    def sleep(self, delay): self.now += delay

class ReceiveTests(unittest.TestCase):
    def run_wait(self, deadline, responses):
        clock = Clock()
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)
            (path / 'request.json').write_text(json.dumps({'run_id': 1, 'run_attempt': 1, 'jobs': []}))
            (path / 'entries.json').write_text('{}')
            (path / 'runner-private.pem').write_bytes(b'private')
            out = io.StringIO()
            with patch.object(runner_manager.time, 'monotonic', clock.monotonic), \
                 patch.object(runner_manager.time, 'time', clock.time), \
                 patch.object(runner_manager.time, 'sleep', clock.sleep), \
                 patch.object(runner_manager.runner_result_client, 'receive', side_effect=responses) as poll, \
                 contextlib.redirect_stdout(out):
                with self.assertRaises(TimeoutError):
                    runner_manager.receive(None, path, 'token', 'trusted', deadline_epoch=deadline,
                                           interval=15, progress_interval=20)
            return clock.now, poll.call_count, out.getvalue()

    def test_short_remaining_job_budget_and_progress(self):
        end, count, text = self.run_wait(1130, [None] * 5)
        self.assertEqual(end, 130)
        self.assertEqual(count, 2)
        self.assertIn('result_pending', text)
        self.assertIn('verbleibend=30s', text)

    def test_periodic_progress_is_repeated(self):
        _, count, text = self.run_wait(1160, [None] * 5)
        self.assertEqual(count, 4)
        self.assertEqual(text.count('result_pending'), 2)

    def test_expired_deadline_does_not_poll(self):
        _, count, _ = self.run_wait(1099, [])
        self.assertEqual(count, 0)

    def test_transport_failure_is_distinguished(self):
        _, _, text = self.run_wait(1115, [urllib.error.URLError('private detail')])
        self.assertIn('transport_error', text)
        self.assertNotIn('private detail', text)

if __name__ == '__main__': unittest.main()
