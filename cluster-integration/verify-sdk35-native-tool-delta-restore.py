"""Restore only an appended native artifact; reuse a verified unchanged baseline."""
import argparse,pathlib,json,hashlib,subprocess,shutil,time,uuid,os
p=argparse.ArgumentParser();p.add_argument('--baseline-manifest',type=pathlib.Path,required=True);p.add_argument('--baseline-restore-stage',type=pathlib.Path,required=True);p.add_argument('--native-id',required=True);a=p.parse_args();R=pathlib.Path('/runtime-build');C=pathlib.Path('/opt/tlc/sdk35-dev');sha=lambda f:hashlib.file_digest(f.open('rb'),'sha256').hexdigest()
assert a.baseline_manifest.resolve().is_relative_to((R/'contract').resolve()) and a.baseline_restore_stage.resolve().is_relative_to((R/'contract').resolve())
current=json.loads((C/'sdk35-dev-module-sources.json').read_text());baseline=json.loads(a.baseline_manifest.read_text());old=baseline.get('native_toolchains',[]);new=current.get('native_toolchains',[]);assert {k:v for k,v in current.items() if k!='native_toolchains'}=={k:v for k,v in baseline.items() if k!='native_toolchains'};assert new[:len(old)]==old and len(new)==len(old)+1 and new[-1]['id']==a.native_id
stage=json.loads((a.baseline_restore_stage/'result.json').read_text());assert stage['container_exit_code']==stage['wrapper_exit_code']==0 and not stage['container_state']['OOMKilled'] and not stage['infrastructure_errors'] and not stage['cleanup_errors'];proof=json.loads((a.baseline_restore_stage/'stdout.log').read_text().splitlines()[-1]);checks=proof['native_integrity_negative_checks'];assert proof['native_toolchains_restored_and_verified']==len(old) and {x['id'] for x in checks}=={x['id'] for x in old} and all(x['corruption_rejected'] and x['test_copy_restored_and_reverified'] for x in checks)
root=pathlib.PurePosixPath(new[-1]['root'])
for t in old:
 other=pathlib.PurePosixPath(t['root']);assert not root.is_relative_to(other) and not other.is_relative_to(root)
O=R/'cache'/('native-delta-restore-'+time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())+'-'+uuid.uuid4().hex[:8]);(O/'contract').mkdir(parents=True);fixture=dict(current);fixture['projects']=[];fixture['native_toolchains']=[new[-1]];(O/'sdk35-dev-module-sources.json').write_text(json.dumps(fixture))
for n in ['coherent-source-lock.json','build-tools-manufacturing-lock.xml']:shutil.copy2(C/'contract'/n,O/'contract'/n)
command=['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--cache-root',str(C)];subprocess.run(command+['--restore-missing'],check=True);tool=new[-1];D=O/'aosp'/tool['root'];probe=D/tool['integrity_probe'];assert probe.resolve().is_relative_to(O.resolve())
with probe.open('r+b') as f:original=f.read(1);f.seek(0);f.write(bytes([original[0]^1]))
try:
 q=subprocess.run(command,capture_output=True,text=True);assert q.returncode!=0 and 'Native toolchain content drift' in q.stderr
finally:
 with probe.open('r+b') as f:f.write(original)
subprocess.run(command,check=True)
source=D/'native-probes/original-format.cpp'
for args in [['-cc1','-fsyntax-only','-verify','-Wformat-pedantic'],['-cc1','-fsyntax-only','-fdiagnostics-parseable-fixits','-Wformat','-verify=okay']]:subprocess.run([str(D/'bin/clang'),*args,str(source)],check=True)
ordinary=D/'native-probes/ordinary-format-error.cpp';q=subprocess.run([str(D/'bin/clang'),'-fsyntax-only','-Wformat','-Werror',str(ordinary)],capture_output=True,text=True);assert q.returncode!=0 and 'format' in q.stderr
native=D/'native-probes/roundtrip';assert subprocess.run([str(native)]).returncode==42
subprocess.run([str(D/'bin/clang'),'-g','-c',str(D/'native-probes/answer.c'),'-o',str(O/'answer.o')],check=True)
subprocess.run([str(D/'bin/llvm-ar'),'rcs',str(O/'libanswer.a'),str(O/'answer.o')],check=True)
native=O/'roundtrip';subprocess.run([str(D/'bin/clang'),'-g','-fuse-ld=lld','--ld-path='+str(D/'bin/ld.lld'),str(D/'native-probes/main.c'),str(O/'libanswer.a'),'-o',str(native)],check=True);assert subprocess.run([str(native)]).returncode==42
env=dict(os.environ,CLANG_BIN=str(D/'bin'),XZ=str(C/'aosp/prebuilts/build-tools/linux_musl-arm64/bin/xz'),CREATE_MINIDEBUGINFO=str(C/'aosp/prebuilts/build-tools/linux_musl-arm64/bin/create_minidebuginfo'));out=O/'roundtrip.stripped';subprocess.run(['bash',str(D/'native-probes/original-strip.sh'),'--keep-mini-debug-info','-i',str(native),'-o',str(out),'-d',str(O/'strip.d')],env=env,check=True);assert subprocess.run([str(out)]).returncode==42;headers=subprocess.check_output([str(D/'bin/llvm-readelf'),'-h','-S',str(out)],text=True);assert 'AArch64' in headers and '.gnu_debugdata' in headers
result={'isolated_root':str(O),'new_native_toolchain_restored_and_verified':tool['id'],'source_projects_restored_in_delta_test':0,'unchanged_native_toolchains_reused':len(old),'baseline_manifest_sha256':sha(a.baseline_manifest),'baseline_full_restore_stage':str(a.baseline_restore_stage),'baseline_full_restore_result_sha256':sha(a.baseline_restore_stage/'result.json'),'baseline_native_prefix_identical':True,'new_artifact_corruption_rejected':True,'restored_original_compiler_tests_passed':True,'ordinary_format_error_still_rejected':True,'restored_native_link_run_exit':42,'restored_original_strip_and_run_exit':42,'gnu_debugdata_present':True,'network_fetch_used':False,'production_checkout_modified':False};(O/'restore-result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
