"""Resolve platform pins plus the explicitly pinned build-tools OpenSSL input."""
import hashlib,json,pathlib,subprocess,xml.etree.ElementTree as ET
PARENT='prebuilts/build-tools'
PARENT_REV='770c104a7909083b8b54d02e6d55351fe1351d5d'
PROOF='contract/build-tools-manufacturing-lock.xml'
SHA='800413ad1de4a2d109217c3666db2137e9a7953dc895e547d3cc3d99c9c77d4e'
BLOB='e05096bb616dd5091193b521c4a02dd3322a5504'
EXPECTED={'path':'external/openssl','name':'platform/external/openssl','revision':'1fcb44724d9276e363100a07aad5ba29bdb4e960'}
REF={'parent_project':PARENT,'parent_revision':PARENT_REV,'source_file':'manifest.xml','proof_file':PROOF,'sha256':SHA,'git_blob_sha1':BLOB,'projects':['external/openssl']}

def load_locked_projects(root,manifest=None):
 root=pathlib.Path(root)
 if manifest is None:manifest=json.loads((root/'sdk35-dev-module-sources.json').read_text())
 raw=(root/'contract/coherent-source-lock.json').read_bytes()
 assert hashlib.sha256(raw).hexdigest()==manifest['lock_sha256'],'Platform source lock drift'
 projects={p['path']:p for p in json.loads(raw)['projects']}
 refs=manifest.get('manufacturing_locks',[])
 assert len(refs)<=1,'Unreviewed manufacturing lock'
 for ref in refs:
  assert ref==REF,'Unreviewed manufacturing lock metadata'
  assert projects[PARENT]['revision']==PARENT_REV and projects[PARENT]['name']=='platform/prebuilts/build-tools'
  data=(root/PROOF).read_bytes()
  assert hashlib.sha256(data).hexdigest()==SHA,'Manufacturing manifest integrity drift'
  assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==BLOB,'Manufacturing Git blob drift'
  parent=root/'aosp'/PARENT
  if (parent/'.git').exists():
   original=subprocess.check_output(['git','-c','safe.directory='+str(parent),'-C',str(parent),'show',PARENT_REV+':manifest.xml'])
   assert original==data,'Manufacturing proof differs from original locked Git object'
  matches=[p for p in ET.fromstring(data).findall('project') if p.get('path')==EXPECTED['path']]
  assert len(matches)==1
  entry={k:matches[0].get(k) for k in EXPECTED}
  assert entry==EXPECTED,'Unexpected supplemental OpenSSL identity'
  assert EXPECTED['path'] not in projects,'Manufacturing lock cannot override platform lock'
  projects[EXPECTED['path']]=entry
 return projects
