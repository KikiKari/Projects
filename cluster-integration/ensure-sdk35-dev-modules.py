"""Verify persistent locked SDK35 modules; optionally restore missing projects only."""
import argparse,hashlib,json,os,pathlib,re,shutil,struct,subprocess,sys
p=argparse.ArgumentParser();p.add_argument('--root',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parent);p.add_argument('--restore-missing',action='store_true');p.add_argument('--cache-root',type=pathlib.Path,default=pathlib.Path('/opt/tlc/sdk35-dev'));a=p.parse_args();root=a.root.resolve()
manifest=json.loads((root/'sdk35-dev-module-sources.json').read_text());lockpath=root/'contract/coherent-source-lock.json'
assert hashlib.sha256(lockpath.read_bytes()).hexdigest()==manifest['lock_sha256'],'Unexpected source lock; no changes performed'
from sdk35_source_locks import load_locked_projects
locked=load_locked_projects(root,manifest);report=[]
for entry in manifest['projects']:
 name=entry['path'];expected=locked[name];dest=root/'aosp'/name
 assert expected['revision']==entry['revision'] and expected['name']==entry['remote_project']
 if not (dest/'.git').exists():
  if not a.restore_missing:raise RuntimeError('Missing persistent source project: '+name)
  cached=a.cache_root/'aosp'/name
  if dest.exists():raise RuntimeError('Existing unmanaged directory; refusing overwrite: '+str(dest))
  if (cached/'.git').exists():
   cached_head=subprocess.check_output(['git','-c','safe.directory='+str(cached),'-C',str(cached),'rev-parse','HEAD'],text=True).strip()
   assert cached_head==entry['revision'],'Cached revision mismatch'
   dest.parent.mkdir(parents=True,exist_ok=True);shutil.copytree(cached,dest,symlinks=True)
  else:subprocess.run(['bash','./run-sdk35-runtime-stage.sh','source-locked',name],cwd=root,check=True)
 head=subprocess.check_output(['git','-c','safe.directory='+str(dest),'-C',str(dest),'rev-parse','HEAD'],text=True).strip()
 assert head==entry['revision'],'Unexpected checkout revision; refusing reset: '+name
 remote=subprocess.check_output(['git','-c','safe.directory='+str(dest),'-C',str(dest),'remote','get-url','origin'],text=True).strip()
 assert remote=='https://android.googlesource.com/'+entry['remote_project']
 for definition in entry['definitions']:
  f=dest/definition['file'];b=f.read_bytes();assert hashlib.sha256(b).hexdigest()==definition['sha256'], 'Module definition drift: '+str(f)
  assert re.search(r'\bname\s*:\s*"'+re.escape(definition['source_module'])+r'"',b.decode()),definition
 for asset in entry.get('assets',[]):
  rel=pathlib.PurePosixPath(asset['file']);assert not rel.is_absolute() and '..' not in rel.parts
  data=(dest/rel).read_bytes();assert hashlib.sha256(data).hexdigest()==asset['sha256'], 'Toolchain asset drift: '+str(rel)
  blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest();assert blob==asset['git_blob_sha1']
  original=subprocess.check_output(['git','-c','safe.directory='+str(dest),'-C',str(dest),'show',entry['revision']+':'+str(rel)])
  assert original==data, 'Toolchain asset differs from locked Git object: '+str(rel)
 report.append({'path':name,'revision':head,'definitions_verified':len(entry['definitions'])})
native_reports=[];source_overlays={}
for toolchain in manifest.get('native_toolchains',[]):
 rel=pathlib.PurePosixPath(toolchain['root']);assert not rel.is_absolute() and '..' not in rel.parts
 assert rel.as_posix().startswith('prebuilts/rust/linux-arm64/') or rel.as_posix() in ['prebuilts/clang/host/linux-x86/native-arm64-runtime','prebuilts/clang/host/linux-x86/native-arm64-host-runtimes','prebuilts/clang/host/linux-x86/native-arm64-host-port-v2','prebuilts/clang/host/linux-x86/native-arm64-fuzzer-runtime','prebuilts/clang/host/linux-x86/native-arm64-asan-runtime','prebuilts/clang/host/linux-x86/native-arm64-readelf-runtime','prebuilts/clang/host/linux-arm64/native-tools-r530567-ar-v1','prebuilts/go/linux-arm64/native-go-1.22-sdk-v1','prebuilts/clang/host/linux-arm64/native-clang-r530567-v1','prebuilts/clang/host/linux-arm64/native-clang-r530567-bindgen-v1','prebuilts/clang/host/linux-arm64/native-clang-r530567-bindgen-cxx-v1']
 dest=root/'aosp'/rel
 if not dest.exists():
  assert a.restore_missing,'Missing native toolchain: '+str(dest)
  cached=a.cache_root/'aosp'/rel;assert cached.is_dir(),'Native toolchain cache miss; no substitute/fetch allowed'
  dest.parent.mkdir(parents=True,exist_ok=True);shutil.copytree(cached,dest,symlinks=True)
 inventory=dest/toolchain['inventory'];assert inventory.parent==dest
 assert hashlib.sha256(inventory.read_bytes()).hexdigest()==toolchain['inventory_sha256']
 data=json.loads(inventory.read_text());actual={}
 for f in dest.rglob('*'):
  if f==inventory:continue
  name=f.relative_to(dest).as_posix()
  if f.is_symlink():
   assert f.resolve().is_relative_to(dest.resolve()),'Native symlink escapes toolchain: '+name
   actual[name]={'kind':'symlink','target':os.readlink(f)}
  elif f.is_file():
   with f.open('rb') as stream:digest=hashlib.file_digest(stream,'sha256').hexdigest()
   actual[name]={'kind':'file','sha256':digest,'mode':f.stat().st_mode & 0o777}
 assert actual==data['files'],'Native toolchain content drift: '+toolchain['id']
 versions={}
 for name,expected in data['verified_versions'].items():
  f=dest/'bin'/name
  with f.open('rb') as stream:header=stream.read(20)
  assert header[:4]==b'\x7fELF' and struct.unpack('<H',header[18:20])[0]==183
  args=data.get('version_args',{}).get(name,['--version']);assert isinstance(args,list) and all(isinstance(x,str) for x in args)
  version=subprocess.check_output([str(f),*args],text=True).strip();assert version==expected
  versions[name]=version
 native_reports.append({'id':toolchain['id'],'root':str(dest),'files_verified':len(actual),'versions':versions,'provenance_sha256':toolchain['inventory_sha256']})
 for overlay in toolchain.get('source_overlays',[]):
  assert overlay['target'] in ['prebuilts/clang/host/linux-x86/soong/clangprebuilts.go','build/soong/rust/config/arm_linux_host.go','build/soong/rust/proc_macro.go','build/soong/rust/rust.go','build/soong/rust/binary.go']
  part=pathlib.PurePosixPath(overlay['source']);assert not part.is_absolute() and '..' not in part.parts
  snapshot=dest/part;assert snapshot.resolve().is_relative_to(dest.resolve())
  assert hashlib.sha256(snapshot.read_bytes()).hexdigest()==overlay['sha256']
  source_overlays[overlay['target']]=overlay
for target,overlay in source_overlays.items():
 dest=root/'aosp'/target
 if not dest.exists():
  assert a.restore_missing,'Missing preserved host source overlay: '+target
  cached=a.cache_root/'aosp'/target;assert hashlib.sha256(cached.read_bytes()).hexdigest()==overlay['sha256']
  dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(cached,dest)
 assert hashlib.sha256(dest.read_bytes()).hexdigest()==overlay['sha256'],'Host source overlay drift: '+target
print(json.dumps({'persistent_root':str(root),'projects':report,'module_count':sum(len(x['definitions']) for x in manifest['projects']),'native_toolchains':native_reports,'native_source_overlays_verified':list(source_overlays),'native_tools_executed':bool(native_reports),'libraries_compiled':False,'runtime_verified':False},indent=2))
