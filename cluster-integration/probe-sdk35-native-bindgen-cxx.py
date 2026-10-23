"""Both original Binder and Input commands, without extra consumer flags."""
import pathlib,argparse,subprocess,json,hashlib,re
p=argparse.ArgumentParser();p.add_argument('--tool-root',type=pathlib.Path,required=True);p.add_argument('--output-root',type=pathlib.Path,required=True);a=p.parse_args();R=pathlib.Path('/runtime-build');A=R/'aosp';D=a.tool_root.resolve();O=a.output_root.resolve();assert D.is_relative_to(R) and O.is_relative_to(R);O.mkdir(parents=True,exist_ok=True);sha=lambda f:hashlib.file_digest(f.open('rb'),'sha256').hexdigest()
subprocess.run(['python3',str(D/'native-probes/probe-base.py'),'--tool-root',str(D),'--output-root',str(O/'binder')],check=True);result=json.loads((O/'binder/probe-result.json').read_text())
trace=subprocess.run([str(D/'bin/clang'),'-E','-x','c++','-v','-'],input='',capture_output=True,text=True);assert trace.returncode==0
search=trace.stderr.split('#include <...> search starts here:')[-1].split('End of search list.')[0];assert not re.search(r'/include/c\+\+/\d',search),search
(O/'native-cxx-search-trace.txt').write_text(trace.stderr)
inputs=json.loads((D/'native-probes/input-inputs.json').read_text())
for n,h in inputs.items():assert sha(A/n)==h
command=(D/'native-probes/original-input-bindgen-command.txt').read_text();assert '-stdlib=' not in command
command=command.replace('__CLANG__',str(D/'bin/clang')).replace('__LIBCLANG__',str(D/'lib')).replace('__OUTPUT__',str(O/'input-bindings.rs'))
with (O/'input.stdout').open('w') as stdout,(O/'input.stderr').open('w') as stderr:q=subprocess.run(['bash','-c',command],cwd=A,stdout=stdout,stderr=stderr)
assert q.returncode==0,(O/'input.stderr').read_text()[-6000:]
text=(O/'input-bindings.rs').read_text();assert 'AMOTION_EVENT_ACTION_CANCEL' in text and len(text)>1000
result.update({'native_configuration_adaptation':'CLANG_DEFAULT_CXX_STDLIB=libc++; existing explicit Soong libc++ headers retained','implicit_gcc_cxx_include_paths_absent':True,'actual_original_input_bindgen_exit':q.returncode,'generated_input_binding_bytes':(O/'input-bindings.rs').stat().st_size,'generated_input_binding_sha256':sha(O/'input-bindings.rs'),'extra_consumer_flags_used':False});(O/'probe-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
