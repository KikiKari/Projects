"""Select only the manufactured, inventoried original native ARM64 compiler."""
import pathlib,json,hashlib,subprocess,struct
A=pathlib.Path('/runtime-build/aosp');R=A.parent
relative='prebuilts/clang/host/linux-arm64/native-clang-r530567-v1';D=A/relative
m=json.loads((R/'sdk35-dev-module-sources.json').read_text())
t=next(x for x in m['native_toolchains'] if x['id']=='clang-r530567-aarch64-native-compiler-v1');assert t['root']==relative
sha=lambda p:hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
assert sha(D/t['inventory'])==t['inventory_sha256']
i=json.loads((D/t['inventory']).read_text());v=i['provenance'];assert v['build']['patch_count']==48 and v['original_format_test_modes_passed']==2 and v['ordinary_format_error_still_rejected']
assert v['native_link_run_exit']==v['original_strip_run_exit']==42
for name in ['clang','clang++','ld.lld','llvm-ar','llvm-nm','llvm-objcopy','llvm-readelf','llvm-strip']:
 p=D/'bin'/name;assert p.resolve().is_relative_to(D.resolve())
 with p.open('rb') as f:h=f.read(20)
 assert h[:4]==b'\x7fELF' and struct.unpack('<H',h[18:20])[0]==183
 entry=i['files'][p.resolve().relative_to(D).as_posix()];assert sha(p)==entry['sha256']
for name,h in v['atomic_packaging_sha256'].items():assert sha(D/'lib/clang/19/include'/name)==h
version=subprocess.check_output([str(D/'bin/clang'),'-dumpversion'],text=True).strip();assert version==i['verified_versions']['clang'] and version.startswith('19.')
print(json.dumps({'native_compiler':relative,'version':version,'inventory_sha256':t['inventory_sha256'],'original_source_tests_passed':True}))
