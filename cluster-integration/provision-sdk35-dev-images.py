"""Local-only image support layers; shared locked source volume; no runtime tests."""
import hashlib,json,os,pathlib,subprocess,time,uuid
from sdk35_process import Abort,run_group
R=pathlib.Path('/home/codex/tlc-integration/sdk35-runtime-build');O=R/'contract'/('dev-images-'+time.strftime('%Y%m%dT%H%M%SZ',time.gmtime())+'-'+uuid.uuid4().hex[:8]);O.mkdir();abort=Abort();abort.install()
config=json.loads((R/'sdk35-module-cache.json').read_text());context=R/'cache'/('sdk35-module-image-'+config['manifest_sha256'][:12]+'-support-'+hashlib.sha256(b''.join((name+'\0').encode()+(R/name).read_bytes() for name in ['sdk35-original-source-finder.go', 'build-sdk35-source-finder.sh','ensure-sdk35-native-compiler.py', 'derive-sdk35-system-sdk.py', 'sdk35_source_locks.py', 'ensure-sdk35-dev-modules.py', 'prepare-sdk35-module-image.py'])).hexdigest()[:12]);events=[]
jobs=[
 ('builder','sha256:5ead3b5c7c2d9f41658476d7bd5140450133d7e36697fc383d450a10d60bb9ee',['tlc-robolectric-builder:arm64-sdk35-20261011']),
 ('android-dev','sha256:c6c1c7d9697b369f92673870e918b0ec374269a4aab8b01a1d3072797979d6db',['tlc-android-dev:arm64-native-20261011','tlc-android-native-test-tools:arm64']),
 ('android-tests','sha256:fc93268835831f85a5a7819c765338d70574c4d75adb47a9fa10c92d9cddba09',['tlc-android-arm64-test-tools:build21','tlc-android-dev:arm64-0pe185-build13-driver'])]
def check():
 s=os.statvfs(R)
 if s.f_bavail*s.f_frsize<42949672960:raise RuntimeError('disk-space')
def small(args):
 check();p=subprocess.run(args,capture_output=True,text=True,timeout=45);events.append({'argv':args,'exit':p.returncode,'stdout':p.stdout,'stderr':p.stderr});(O/'operations.json').write_text(json.dumps(events,indent=2));p.check_returncode();return p.stdout
def inspect(ref):return json.loads(small(['docker','--context','default','image','inspect',ref]))[0]
def long(args,name):
 tick=lambda proc:(O/'heartbeat.json').write_text(json.dumps({'time':time.time(),'pid':proc.pid,'operation':name}))
 result=run_group(args,abort,check,grace=25,tick=tick);events.append({'argv':args,'exit':result,'operation':name});(O/'operations.json').write_text(json.dumps(events,indent=2));assert result==0,(name,result)
results=[];expected_aliases={alias:base for role,base,aliases in jobs for alias in aliases}
try:
 profile_path=R/'sdk35-development-images.json'
 if profile_path.exists():
  existing=json.loads(profile_path.read_text())
  assert existing['source_cache_volume']==config['volume_name']
  (O/'profile-before.json').write_text(json.dumps(existing,indent=2))
  for role,base,aliases in jobs:
   item=next(x for x in existing['images'] if x['role']==role)
   assert item['before']==base and item['aliases']==aliases
   current=inspect(item['after']);original=inspect(base)
   assert current['Architecture']=='arm64' and current['Os']=='linux'
   assert current['RootFS']['Layers'][:len(original['RootFS']['Layers'])]==original['RootFS']['Layers']
   assert current['Config']['Labels']['org.tlc.sdk35.modules.manifest']==existing['manifest_sha256']
   for alias in aliases:assert inspect(alias)['Id']==item['after'],'Unexpected active image: '+alias
  small(['docker','--context','default','volume','inspect',config['volume_name']])
  if existing['manifest_sha256']==config['manifest_sha256']:
   (O/'reuse-verified.json').write_text(json.dumps(existing,indent=2))
   print(json.dumps({'evidence':str(O),'reused_existing_images':True,'images_rebuilt':False}));raise SystemExit(0)
  expected_aliases={alias:item['after'] for item in existing['images'] for alias in item['aliases']}
 for role,base,aliases in jobs:
  old=inspect(base);assert old['Architecture']=='arm64' and old['Os']=='linux'
  for alias in aliases:assert inspect(alias)['Id']==expected_aliases[alias],'Unexpected active image: '+alias
  backup='tlc-sdk35-base:'+role+'-'+base[7:19];small(['docker','--context','default','tag',base,backup])
  tag='tlc-sdk35-dev:'+role+'-modules-'+config['manifest_sha256'][:12]
  long(['docker','--context','default','buildx','build','--builder','default','--platform','linux/arm64','--network','none','--progress','plain','--load','--build-arg','BASE_IMAGE='+backup,'--metadata-file',str(O/(role+'-build-metadata.json')),'-t',tag,str(context)],'image-'+role)
  new=inspect(tag);assert new['Architecture']=='arm64' and new['Os']=='linux'
  for field in ['User','Entrypoint','Cmd','WorkingDir']:assert old['Config'].get(field)==new['Config'].get(field),(role,field)
  assert new['RootFS']['Layers'][:len(old['RootFS']['Layers'])]==old['RootFS']['Layers']
  (O/(role+'-before.json')).write_text(json.dumps(old,indent=2));(O/(role+'-after.json')).write_text(json.dumps(new,indent=2))
  long(['env','TLC_SDK35_STAGE_IMAGE='+new['Id'],'bash',str(R/'run-sdk35-runtime-stage.sh'),'module-image-verify-'+role],'verify-'+role)
  results.append({'role':role,'before':base,'after':new['Id'],'versioned_tag':tag,'backup':backup,'aliases':aliases})
 # Promote only after all three images and fresh-container checks succeeded.
 for item in results:
  for alias in item['aliases']:
   assert inspect(alias)['Id']==expected_aliases[alias],'Concurrent alias change; refusing overwrite'
   small(['docker','--context','default','tag',item['after'],alias])
 profile={'schema':1,'source_cache_volume':config['volume_name'],'manifest_sha256':config['manifest_sha256'],'runtime_builder_image':next(x['after'] for x in results if x['role']=='builder'),'android_test_image':next(x['after'] for x in results if x['role']=='android-tests'),'images':results,'public_push':False}
 (O/'result.json').write_text(json.dumps(profile,indent=2));(R/'sdk35-development-images.json').write_text(json.dumps(profile,indent=2));print(json.dumps({'evidence':str(O),'profile':profile}))
except Exception as error:
 (O/'failure.json').write_text(json.dumps({'error':repr(error),'completed_images':results},indent=2));raise
