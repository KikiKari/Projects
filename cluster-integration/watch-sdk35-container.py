"""Bounded Docker control with separate operation, container and wrapper results."""
import json, os, re, subprocess, sys, time, uuid
from pathlib import Path
from sdk35_process import Abort

class DockerError(RuntimeError): pass

class Docker:
    def __init__(self, evidence):
        self.evidence=evidence; self.operations=[]; self.cid=None
    def call(self, *args, timeout=35):
        began=time.time(); clock=time.monotonic()
        entry={'operation':args[0], 'container_id':self.cid, 'args':list(args),
               'started_at':began, 'returncode':None, 'timeout':False}
        try:
            result=subprocess.run(['docker',*args], capture_output=True, text=True, timeout=timeout)
            entry.update(returncode=result.returncode, stdout=result.stdout, stderr=result.stderr)
        except subprocess.TimeoutExpired as error:
            def decode(value): return value.decode(errors='replace') if isinstance(value,bytes) else value or ''
            entry.update(timeout=True, stdout=decode(error.stdout), stderr=decode(error.stderr))
        except OSError as error:
            entry.update(stdout='',stderr=repr(error))
        entry.update(finished_at=time.time(), duration=time.monotonic()-clock)
        self.operations.append(entry)
        with (self.evidence/'docker-operations.jsonl').open('a') as f:
            f.write(json.dumps(entry)+'\n')
        if entry['timeout'] or entry['returncode'] != 0:
            raise DockerError(f"Docker {args[0]} failed: {entry}")
        return entry['stdout'].strip()
    def state(self):
        if not self.cid: raise DockerError('No validated container ID')
        return json.loads(self.call('inspect','--format','{{json .State}}',self.cid))
    def stop_confirmed(self):
        errors=[]
        try:self.call('stop','--timeout','25',self.cid,timeout=35)
        except Exception as error:errors.append(repr(error))
        try:current=self.state()
        except Exception as error:current=None;errors.append(repr(error))
        if current is None or current['Running']:
            try:self.call('kill',self.cid)
            except Exception as error:errors.append(repr(error))
            try:current=self.state()
            except Exception as error:current=None;errors.append(repr(error))
        return current,errors

def main(stage, command):
    root=Path.cwd()
    run_id='stage-'+stage+'-'+time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())+'-'+uuid.uuid4().hex[:8]
    run=root/'contract'/run_id;run.mkdir(parents=True)
    abort=Abort();abort.install();docker=Docker(run)
    reason=None;final=None;infra=[];cleanup_errors=[];wrapper_exit=125
    status=run/'status.json';last=time.monotonic();previous=None;terminal_since=None
    try:
        disk=os.statvfs(root)
        if disk.f_bavail*disk.f_frsize < 40*1024**3:
            reason='disk-space';raise RuntimeError(reason)
        inside='/runtime-build/'+str(status.relative_to(root))
        module_mount=[]
        module_config=root/'sdk35-module-cache.json'
        if module_config.exists():
            module_volume=json.loads(module_config.read_text())['volume_name']
            if not re.fullmatch(r'tlc-sdk35-modules-[a-z0-9-]+',module_volume):raise ValueError('Unexpected module cache volume')
            docker.call('volume','inspect',module_volume)
            module_mount=['-v',module_volume+':/opt/tlc/sdk35-dev'+('' if stage=='module-cache-seed' else ':ro')]
        stage_user='0:0' if stage=='module-cache-seed' else f'{os.getuid()}:{os.getgid()}'
        stage_image=os.environ.get('TLC_SDK35_STAGE_IMAGE','tlc-robolectric-builder:arm64-sdk35-20261011')
        if stage_image!='tlc-robolectric-builder:arm64-sdk35-20261011' and not re.fullmatch(r'sha256:[0-9a-f]{64}',stage_image):raise ValueError('Immutable image ID required for stage override')
        candidate=docker.call('create','--cpus','8','--memory','16g','--memory-swap','16g',
            '--pids-limit','2048','--user',stage_user,
            '-e','HOME=/runtime-build','-e','SDK35_STAGE_STATUS='+inside,
            '-v',str(root)+':/runtime-build',*module_mount,stage_image,
            'python3','/runtime-build/guard-sdk35-stage.py',*command)
        if not re.fullmatch('[0-9a-f]{64}',candidate):raise DockerError('Invalid container ID from create')
        docker.cid=candidate;(run/'container-id').write_text(candidate+'\n')
        if abort.signal is not None:reason='signal';raise InterruptedError('signal during create')
        docker.call('start',docker.cid)
        last=time.monotonic()
        while True:
            disk=os.statvfs(root)
            if disk.f_bavail*disk.f_frsize < 40*1024**3:reason='disk-space'
            elif abort.signal is not None:reason='signal'
            current=docker.state()
            if not current['Running']:
                final=current;wrapper_exit=current['ExitCode'];break
            if status.exists():
                content=status.read_bytes();value=json.loads(content)
                if content != previous:last=time.monotonic();previous=content
                if value['state'] in ('failed','aborted','finished'):
                    if terminal_since is None:terminal_since=time.monotonic()
                    if time.monotonic()-terminal_since>5 and reason is None:
                        reason='terminal-stage-container-running'
            if reason is None and time.monotonic()-last>30:reason='stage-heartbeat-timeout'
            if reason:
                final,cleanup_errors=docker.stop_confirmed()
                wrapper_exit=1;break
            time.sleep(2)
    except BaseException as error:
        infra.append(repr(error))
        if docker.cid:
            # Inspect first: failed CLI operations may already have changed daemon state.
            try:final=docker.state()
            except Exception as inspect_error:infra.append(repr(inspect_error));final=None
            if final is None or final['Running']:
                final,cleanup_errors=docker.stop_confirmed()
    finally:
        if docker.cid:
            try:
                final=docker.state()
            except Exception as error:infra.append(repr(error));final=None
            try:
                docker.call('logs',docker.cid)
                entry=docker.operations[-1]
                (run/'stdout.log').write_text(entry['stdout'])
                (run/'stderr.log').write_text(entry['stderr'])
            except Exception as error:infra.append(repr(error))
        confirmed=final is not None
        cleanup_confirmed=confirmed and not final['Running']
        stage_reason=None
        if status.exists():
            try:stage_reason=json.loads(status.read_text()).get('reason')
            except Exception as error:infra.append('status-read: '+repr(error))
        if reason=='disk-space' or stage_reason=='disk-space':
            reason='disk-space';wrapper_exit=75
        elif reason=='signal' or abort.signal is not None:
            reason='signal';wrapper_exit=128+abort.signal
        elif infra or cleanup_errors or not cleanup_confirmed:
            wrapper_exit=125
        report={'run_id':run_id,'container_id':docker.cid,'abort_reason':reason,
            'wrapper_exit_code':wrapper_exit,'container_exit_code':final['ExitCode'] if cleanup_confirmed else None,
            'container_state_confirmed':confirmed,'cleanup_confirmed':cleanup_confirmed,
            'container_state':final,'infrastructure_errors':infra,'cleanup_errors':cleanup_errors,
            'docker_operations':docker.operations,'container_retained':bool(docker.cid)}
        (run/'result.json').write_text(json.dumps(report,indent=2))
        print('EVIDENCE',run,flush=True)
    return wrapper_exit

if __name__=='__main__':sys.exit(main(sys.argv[1],sys.argv[2:]))
