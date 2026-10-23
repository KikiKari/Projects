"""Seed or extend the managed cache, preserving existing locked projects."""
import configparser,hashlib,json,os,pathlib,shutil,subprocess,uuid
R=pathlib.Path('/runtime-build');C=pathlib.Path('/opt/tlc/sdk35-dev');manifest=json.loads((R/'sdk35-dev-module-sources.json').read_text())
subprocess.run(['python3',str(R/'ensure-sdk35-dev-modules.py'),'--root',str(R)],check=True)
def check():
 s=os.statvfs(R)
 if s.f_bavail*s.f_frsize<42949672960:raise RuntimeError('disk-space')
def copy(src,dst):check();return shutil.copy2(src,dst)

def public_config_allowed(text,remote_project):
 config=configparser.RawConfigParser();config.read_string(text)
 expected='https://android.googlesource.com/'+remote_project
 if config.get('remote "origin"','url',fallback=None)!=expected:return False
 for section in config.sections():
  for key,value in config.items(section):
   if section=='remote "origin"' and key=='url' and value==expected:continue
   if any(marker in (section+'.'+key+'='+value).lower() for marker in ['extraheader','credential','password','oauth','insteadof']):return False
 return True

def identical_tree(src,dst):
 def inventory(root):
  out={}
  for f in root.rglob('*'):
   rel=f.relative_to(root).as_posix()
   if f.is_symlink():out[rel]=('symlink',os.readlink(f))
   elif f.is_file():
    with f.open('rb') as stream:digest=hashlib.file_digest(stream,'sha256').hexdigest()
    out[rel]=('file',f.stat().st_mode & 0o777,digest)
   elif f.is_dir():out[rel]=('directory',)
   else:raise RuntimeError('Unsupported partial-cache entry')
  return out
 return inventory(src)==inventory(dst)

complete=C/'complete.json'
if complete.exists():
 subprocess.run(['python3',str(C/'ensure-sdk35-dev-modules.py'),'--root',str(C)],check=True)
 old_manifest=C/'sdk35-dev-module-sources.json';old=json.loads(old_manifest.read_text())
 incoming={p['path']:p for p in manifest['projects']}
 def additive(previous,current):
  return current is not None and {k:v for k,v in previous.items() if k not in ['definitions','assets']}=={k:v for k,v in current.items() if k not in ['definitions','assets']} and all(current.get(key,[])[:len(previous.get(key,[]))]==previous.get(key,[]) for key in ['definitions','assets'])
 assert all(additive(p,incoming.get(p['path'])) for p in old['projects']),'Cache update must retain all previous definitions'
 assert manifest.get('native_toolchains',[])[:len(old.get('native_toolchains',[]))]==old.get('native_toolchains',[]),'Previous native toolchains must be retained'
 history=C/'history'/hashlib.sha256(old_manifest.read_bytes()).hexdigest();history.mkdir(parents=True,exist_ok=True)
 for rel in ['sdk35-dev-module-sources.json','ensure-sdk35-dev-modules.py','complete.json']:copy(C/rel,history/rel)
for p in manifest['projects']:
 src=R/'aosp'/p['path'];dst=C/'aosp'/p['path']
 if (src/'.git/objects/info/alternates').exists():raise RuntimeError('External Git alternates not portable')
 config=(src/'.git/config').read_text()
 if not public_config_allowed(config,p['remote_project']):raise RuntimeError('Unexpected credential configuration or non-original public remote in cache')
 dst.parent.mkdir(parents=True,exist_ok=True)
 if dst.exists() and complete.exists() and p['path'] not in {x['path'] for x in old['projects']}:
  # A failed additive seed can leave complete copied directories before commit.
  # Preserve only byte-identical partial copies; never silently accept or delete them.
  assert identical_tree(src,dst),'Partial cache differs from locked source; review required: '+p['path']
  recovery=C/'recovery'/('partial-'+hashlib.sha256((R/'sdk35-dev-module-sources.json').read_bytes()).hexdigest()[:12]+'-'+uuid.uuid4().hex[:8])/p['path']
  recovery.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(dst),str(recovery));print('PRESERVED_PARTIAL',p['path'],str(recovery),flush=True)
 if dst.exists():
  assert complete.exists() and p['path'] in {x['path'] for x in old['projects']},'Partial cache retained; review required: '+str(dst)
  assert subprocess.check_output(['git','-c','safe.directory='+str(dst),'-C',str(dst),'rev-parse','HEAD'],text=True).strip()==p['revision']
  print('RETAINED',p['path'],flush=True);continue
 shutil.copytree(src,dst,symlinks=True,copy_function=copy);print('CACHED',p['path'],flush=True)
source_overlays={}
for toolchain in manifest.get('native_toolchains',[]):
 rel=pathlib.PurePosixPath(toolchain['root']);assert not rel.is_absolute() and '..' not in rel.parts
 assert rel.as_posix().startswith('prebuilts/rust/linux-arm64/') or rel.as_posix() in ['prebuilts/clang/host/linux-x86/native-arm64-runtime','prebuilts/clang/host/linux-x86/native-arm64-host-runtimes','prebuilts/clang/host/linux-x86/native-arm64-host-port-v2','prebuilts/clang/host/linux-x86/native-arm64-fuzzer-runtime','prebuilts/clang/host/linux-x86/native-arm64-asan-runtime','prebuilts/clang/host/linux-x86/native-arm64-readelf-runtime','prebuilts/clang/host/linux-arm64/native-tools-r530567-ar-v1','prebuilts/go/linux-arm64/native-go-1.22-sdk-v1','prebuilts/clang/host/linux-arm64/native-clang-r530567-v1','prebuilts/clang/host/linux-arm64/native-clang-r530567-bindgen-v1','prebuilts/clang/host/linux-arm64/native-clang-r530567-bindgen-cxx-v1']
 src=R/'aosp'/rel;dst=C/'aosp'/rel
 if dst.exists():assert identical_tree(src,dst),'Existing native toolchain differs; refusing overwrite'
 else:dst.parent.mkdir(parents=True,exist_ok=True);shutil.copytree(src,dst,symlinks=True,copy_function=copy)
 print('NATIVE_TOOLCHAIN_CACHED',toolchain['id'],flush=True)
 for overlay in toolchain.get('source_overlays',[]):
  target=overlay['target'];assert target in ['prebuilts/clang/host/linux-x86/soong/clangprebuilts.go','build/soong/rust/config/arm_linux_host.go','build/soong/rust/proc_macro.go','build/soong/rust/rust.go','build/soong/rust/binary.go']
  source_overlays[target]=overlay
for target,overlay in source_overlays.items():
 src=R/'aosp'/target;dst=C/'aosp'/target
 assert hashlib.sha256(src.read_bytes()).hexdigest()==overlay['sha256']
 if not dst.exists():
  # A newly catalogued host-port context may have no prior cached source file.
  # Its immutable native-artifact snapshot and manifest hash were verified above.
  assert target in ['build/soong/rust/config/arm_linux_host.go','build/soong/rust/proc_macro.go','build/soong/rust/rust.go','build/soong/rust/binary.go']
  dst.parent.mkdir(parents=True,exist_ok=True)
  temporary=dst.with_name(dst.name+'.verified-'+uuid.uuid4().hex);copy(src,temporary)
  assert hashlib.sha256(temporary.read_bytes()).hexdigest()==overlay['sha256']
  os.replace(temporary,dst)
  print('ADDED_HOST_SOURCE_OVERLAY',target,flush=True)
 current=hashlib.sha256(dst.read_bytes()).hexdigest()
 assert current in [overlay['previous_sha256'],overlay['sha256']],'Unexpected cached host port; refusing overwrite'
 if current!=overlay['sha256']:
  backup=C/'history'/'host-source-overlays'/current/target;backup.parent.mkdir(parents=True,exist_ok=True)
  if backup.exists():assert hashlib.sha256(backup.read_bytes()).hexdigest()==current
  else:copy(dst,backup)
  temporary=dst.with_name(dst.name+'.verified-'+uuid.uuid4().hex);copy(src,temporary)
  assert hashlib.sha256(temporary.read_bytes()).hexdigest()==overlay['sha256'];os.replace(temporary,dst)
 print('PRESERVED_HOST_SOURCE_OVERLAY',target,flush=True)
for rel in ['sdk35-dev-module-sources.json','ensure-sdk35-dev-modules.py','contract/coherent-source-lock.json','sdk35_source_locks.py','contract/build-tools-manufacturing-lock.xml','sdk35-original-source-finder.go','build-sdk35-source-finder.sh','ensure-sdk35-native-compiler.py']:
 dst=C/rel;dst.parent.mkdir(parents=True,exist_ok=True);copy(R/rel,dst)
subprocess.run(['python3',str(C/'ensure-sdk35-dev-modules.py'),'--root',str(C)],check=True)
complete.write_text(json.dumps({'manifest_sha256':hashlib.sha256((C/'sdk35-dev-module-sources.json').read_bytes()).hexdigest(),'projects':len(manifest['projects']),'definitions':sum(len(p['definitions']) for p in manifest['projects']),'offline_source_cache':True},indent=2));print(complete.read_text())
