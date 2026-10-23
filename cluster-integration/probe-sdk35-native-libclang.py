"""Exercise native CIndex and the unchanged real Binder bindgen command."""
import argparse,pathlib,json,hashlib,subprocess,ctypes,os
p=argparse.ArgumentParser();p.add_argument('--tool-root',type=pathlib.Path,required=True);p.add_argument('--output-root',type=pathlib.Path,required=True);a=p.parse_args();R=pathlib.Path('/runtime-build');A=R/'aosp';D=a.tool_root.resolve();O=a.output_root.resolve();assert D.is_relative_to(R) and O.is_relative_to(R);O.mkdir(parents=True,exist_ok=True)
sha=lambda f:hashlib.file_digest(f.open('rb'),'sha256').hexdigest()
inputs=json.loads((D/'native-probes/original-inputs.json').read_text())
for name,h in inputs['source_sha256'].items():assert sha(A/name)==h
assert sha(A/inputs['bindgen_binary'])==inputs['bindgen_binary_sha256']
class CXString(ctypes.Structure):_fields_=[('data',ctypes.c_void_p),('private_flags',ctypes.c_uint)]
lib=ctypes.CDLL(str(D/'lib/libclang.so'));lib.clang_getClangVersion.restype=CXString;lib.clang_getCString.argtypes=[CXString];lib.clang_getCString.restype=ctypes.c_char_p;lib.clang_disposeString.argtypes=[CXString]
value=lib.clang_getClangVersion();version=lib.clang_getCString(value).decode();lib.clang_disposeString(value);assert '19.0.0' in version,version
lib.clang_createIndex.argtypes=[ctypes.c_int,ctypes.c_int];lib.clang_createIndex.restype=ctypes.c_void_p;lib.clang_disposeIndex.argtypes=[ctypes.c_void_p];index=lib.clang_createIndex(0,0);assert index;lib.clang_disposeIndex(index)
command=(D/'native-probes/original-bindgen-command.txt').read_text().replace('__CLANG__',str(D/'bin/clang')).replace('__LIBCLANG__',str(D/'lib')).replace('__OUTPUT__',str(O/'bindings.rs'))
with (O/'bindgen.stdout').open('w') as stdout,(O/'bindgen.stderr').open('w') as stderr:q=subprocess.run(['bash','-c',command],cwd=A,stdout=stdout,stderr=stderr)
assert q.returncode==0,(O/'bindgen.stderr').read_text()[-6000:]
generated=(O/'bindings.rs').read_text();assert 'AIBinder' in generated and len(generated)>10000
result={'native_cindex_version':version,'native_cindex_create_dispose_passed':True,'actual_original_binder_bindgen_exit':q.returncode,'original_consumer_flags_preserved':True,'only_tool_and_output_paths_replaced':True,'generated_binding_bytes':(O/'bindings.rs').stat().st_size,'generated_binding_sha256':sha(O/'bindings.rs'),'native_libclang_sha256':sha(D/'lib/libclang.so')};(O/'probe-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
