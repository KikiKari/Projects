"""Actually restore one locked crate offline into a new isolated workspace."""
import json,pathlib,shutil,subprocess,time,uuid,hashlib
R=pathlib.Path('/runtime-build');C=pathlib.Path('/opt/tlc/sdk35-dev')
manifest=json.loads((C/'sdk35-dev-module-sources.json').read_text())
manifest['projects']=[p for p in manifest['projects'] if p['path'] in ['external/rust/crates/quote','external/openssl','external/squashfs-tools','external/neon_2_sse','external/apache-harmony','build/make']];assert len(manifest['projects'])==6
O=R/'cache'/('restore-check-'+time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())+'-'+uuid.uuid4().hex[:8]);(O/'contract').mkdir(parents=True)
shutil.copy2(C/'contract/coherent-source-lock.json',O/'contract/coherent-source-lock.json')
shutil.copy2(C/'contract/build-tools-manufacturing-lock.xml',O/'contract/build-tools-manufacturing-lock.xml')
(O/'sdk35-dev-module-sources.json').write_text(json.dumps(manifest))
# This new root has no source-fetch runner. A cache miss cannot trigger a fetch.
subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--restore-missing','--cache-root',str(C)],check=True)
assert not (O/'run-sdk35-runtime-stage.sh').exists()
# Restore the two small packaging assets without duplicating the 17-GiB Clang checkout.
clang_entry=next(p for p in json.loads((C/'sdk35-dev-module-sources.json').read_text())['projects'] if p['path']=='prebuilts/clang/host/linux-x86')
packaging_assets=[]
for rel in ['clang-r530567/lib/clang/19/include/stdatomic.h','clang-r530567/lib/clang/19/include/bits/stdatomic.h']:
 asset=next(a for a in clang_entry['assets'] if a['file']==rel);project=C/'aosp'/clang_entry['path'];src=project/rel;dst=O/'restored-packaging-assets'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst);data=dst.read_bytes();assert hashlib.sha256(data).hexdigest()==asset['sha256'];assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==asset['git_blob_sha1'];assert subprocess.check_output(['git','-c','safe.directory='+str(project),'-C',str(project),'show',clang_entry['revision']+':'+rel])==data;packaging_assets.append({'file':rel,'sha256':asset['sha256'],'real_offline_copy':True,'locked_git_object_equal':True})

# Reject corrupted manufacturing proof in the isolated restored root.
proof=O/'contract/build-tools-manufacturing-lock.xml';original=proof.read_bytes()
try:
 proof.write_bytes(bytes([original[0]^1])+original[1:])
 q=subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--cache-root',str(C)],capture_output=True,text=True)
 assert q.returncode!=0 and 'Manufacturing manifest integrity drift' in q.stderr
finally:proof.write_bytes(original)
tamper_checks=[]
for toolchain in manifest.get('native_toolchains',[]):
 # Exercise fail-closed integrity checks only in this newly restored test copy.
 probe=O/'aosp'/toolchain['root']/toolchain.get('integrity_probe','bin/rustc');assert probe.resolve().is_relative_to(O.resolve())
 with probe.open('r+b') as f:original=f.read(1);f.seek(0);f.write(bytes([original[0]^1]))
 try:
  q=subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--cache-root',str(C)],capture_output=True,text=True)
  assert q.returncode!=0 and 'Native toolchain content drift' in q.stderr,'Native toolchain corruption was not rejected'
 finally:
  with probe.open('r+b') as f:f.write(original)
 subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--cache-root',str(C)],check=True)
 tamper_checks.append({'id':toolchain['id'],'corruption_rejected':True,'test_copy_restored_and_reverified':True})
overlay_checks=[]
overlays={x['target']:x for t in manifest.get('native_toolchains',[]) for x in t.get('source_overlays',[])}
for target,overlay in overlays.items():
 probe=O/'aosp'/target;assert probe.resolve().is_relative_to(O.resolve());original=probe.read_bytes()
 try:
  probe.write_bytes(bytes([original[0]^1])+original[1:])
  q=subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--cache-root',str(C)],capture_output=True,text=True)
  assert q.returncode!=0 and 'Host source overlay drift' in q.stderr,'Host port corruption was not rejected'
 finally:probe.write_bytes(original)
 subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(O),'--cache-root',str(C)],check=True)
 overlay_checks.append({'target':target,'corruption_rejected':True,'test_copy_restored_and_reverified':True})
result={'packaging_assets_restored':packaging_assets,'isolated_root':str(O),'projects':['external/rust/crates/quote','external/openssl','external/squashfs-tools','external/neon_2_sse','external/apache-harmony','build/make'],'manufacturing_proof_corruption_rejected':True,'real_source_and_git_copy':True,'native_toolchains_restored_and_verified':len(manifest.get('native_toolchains',[])),'native_integrity_negative_checks':tamper_checks,'native_source_overlay_negative_checks':overlay_checks,'network_fetch_used':False,'production_checkout_modified':False,'runtime_executed':False}
(O/'restore-result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
