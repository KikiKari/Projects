"""Prepare an image support layer; complete sources remain in a shared cache volume."""
import hashlib,json,os,pathlib,subprocess,shutil
R=pathlib.Path('/runtime-build');M=R/'sdk35-dev-module-sources.json';manifest=json.loads(M.read_text())
subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(R)],check=True)
manifest_sha=hashlib.sha256(M.read_bytes()).hexdigest()
O=R/'cache'/('sdk35-module-image-'+manifest_sha[:12]+'-support-'+hashlib.sha256(b''.join((name+'\0').encode()+(R/name).read_bytes() for name in ['sdk35-original-source-finder.go', 'build-sdk35-source-finder.sh','ensure-sdk35-native-compiler.py', 'derive-sdk35-system-sdk.py', 'sdk35_source_locks.py', 'ensure-sdk35-dev-modules.py', 'prepare-sdk35-module-image.py'])).hexdigest()[:12]);O.mkdir(exist_ok=False)
def guard():
 s=os.statvfs(R)
 if s.f_bavail*s.f_frsize<42949672960:raise RuntimeError('disk-space')
support=O/'support';support.mkdir()
for p in manifest['projects']:
 for d in p['definitions']+p.get('assets',[]):
  guard();dest=support/'catalog'/p['path']/d['file'];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/'aosp'/p['path']/d['file'],dest)
for rel in ['sdk35-dev-module-sources.json','ensure-sdk35-dev-modules.py','sdk35-module-cache.json','contract/coherent-source-lock.json','sdk35_source_locks.py','contract/build-tools-manufacturing-lock.xml','sdk35-original-source-finder.go','build-sdk35-source-finder.sh','ensure-sdk35-native-compiler.py','derive-sdk35-system-sdk.py']:
 dest=support/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,dest)
for toolchain in manifest.get('native_toolchains',[]):
 dest=support/'native-toolchains'/toolchain['id']/toolchain['inventory'];dest.parent.mkdir(parents=True,exist_ok=True)
 shutil.copy2(R/'aosp'/toolchain['root']/toolchain['inventory'],dest)
 for overlay in toolchain.get('source_overlays',[]):
  assert overlay['target'] in ['prebuilts/clang/host/linux-x86/soong/clangprebuilts.go','build/soong/rust/config/arm_linux_host.go','build/soong/rust/proc_macro.go','build/soong/rust/rust.go','build/soong/rust/binary.go']
  dest=support/'host-source-overlays'/overlay['target'];dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(R/'aosp'/overlay['target'],dest)
for rel in ['soong/Android.bp','soong/rustprebuilts.go']:
 dest=support/'catalog/prebuilts/rust'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/'aosp/prebuilts/rust'/rel,dest)
dockerfile='''ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY support/ /opt/tlc/sdk35-module-support/
ENV TLC_SDK35_MODULE_CACHE=/opt/tlc/sdk35-dev
LABEL org.tlc.sdk35.modules.lock="7a6951310060b903254cd597e62df49939b576b8e763b96c1c0ca68840ec7337"
LABEL org.tlc.sdk35.modules.manifest="MANIFEST_SHA256"
'''
(O/'Dockerfile').write_text(dockerfile.replace('MANIFEST_SHA256',manifest_sha))
report={'context':str(O),'manifest_sha256':hashlib.sha256(M.read_bytes()).hexdigest(),'repository_count':len(manifest['projects']),'module_count':sum(len(p['definitions']) for p in manifest['projects']),'image_support_layer':True,'complete_source_cache_volume':json.loads((R/'sdk35-module-cache.json').read_text())['volume_name'],'native_tools_executed':bool(manifest.get('native_toolchains')),'native_toolchain_count':len(manifest.get('native_toolchains',[])),'runtime_verified':False}
(O/'context-provenance.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
