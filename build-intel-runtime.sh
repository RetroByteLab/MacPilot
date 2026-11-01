#!/bin/bash
# Candidate-only recipe from RUNTIME_BUILD.md. Never replaces working assets.
# Usage: set the six documented path variables, plus CMAKE (absolute executable),
# then /bin/bash build-intel-runtime.sh. RUNTIME_PROFILE=sse2 (default) or avx2.
# No downloads or inference are performed. Profiles never enable native tuning.
set -euo pipefail
umask 077
trap 'printf "ERROR: runtime preparation failed at line %s. Partial candidate outputs are retained; working assets are untouched.\n" "$LINENO" >&2' ERR
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
RUNTIME_PROFILE=${RUNTIME_PROFILE:-sse2}
case "$RUNTIME_PROFILE" in
  sse2) ISA=OFF ;;
  avx2) ISA=ON ;;
  *) fail 'RUNTIME_PROFILE must be sse2 or avx2.' ;;
esac
readonly RUNTIME_PROFILE ISA
readonly REVISION=5047748f114564fcf271e6a648f60e2d2eae6264
readonly MODEL=qwen2.5-1.5b-instruct-q4_k_m.gguf
readonly MODEL_SHA=6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e
for name in LLAMA_SOURCE RUNTIME_BUILD CANDIDATE_ASSETS CURRENT_ASSETS MACPILOT_SOURCE DEVELOPER_DIR CMAKE; do
  [[ -n "${!name:-}" && "${!name}" = /* ]] || fail "Set $name to an absolute path."
done
[[ $(/usr/bin/uname -s) = Darwin && $(/usr/bin/uname -m) = x86_64 ]] || fail 'Requires a native Intel macOS build host.'
[[ $(/usr/sbin/sysctl -in sysctl.proc_translated 2>/dev/null || true) != 1 ]] || fail 'Rosetta build hosts are not supported.'
[[ -x "$CMAKE" && -d "$DEVELOPER_DIR" ]] || fail 'CMake executable or Xcode developer directory is missing.'
for tool in /usr/bin/python3 /usr/bin/git /usr/bin/make /usr/bin/xcrun /usr/bin/xcodebuild /usr/bin/lipo /usr/bin/otool /usr/bin/shasum /usr/bin/cmp /usr/bin/tee; do
  [[ -x "$tool" ]] || fail "Missing dependency: $tool"
done
# Canonical-path checks prevent symlink aliases or nested outputs touching inputs.
/usr/bin/python3 - "$LLAMA_SOURCE" "$CURRENT_ASSETS" "$MACPILOT_SOURCE" "$RUNTIME_BUILD" "$CANDIDATE_ASSETS" <<'PY_PATHS'
import sys, os
from pathlib import Path
inputs=[Path(x).resolve(strict=True) for x in sys.argv[1:4]]
outputs=[]
for raw in sys.argv[4:]:
 p=Path(raw)
 assert not os.path.lexists(str(p)), 'Output already exists: '+str(p)
 assert p.parent.is_dir(), 'Output parent must already exist: '+str(p.parent)
 outputs.append(p.parent.resolve(strict=True)/p.name)
for output in outputs:
 for other in inputs+[x for x in outputs if x!=output]:
  assert output!=other and output not in other.parents and other not in output.parents, 'Input/output paths overlap'
assert outputs[0]!=outputs[1], 'Outputs must be distinct'
PY_PATHS
[[ $(cd "$MACPILOT_SOURCE" && /bin/pwd -P) = $(cd "$(/usr/bin/dirname "$0")" && /bin/pwd -P) ]] || fail "MACPILOT_SOURCE must be this script’s repository root."
[[ -f "$LLAMA_SOURCE/CMakeLists.txt" && -f "$MACPILOT_SOURCE/THIRD_PARTY_NOTICES.md" ]] || fail 'Source or current notices missing.'
[[ $(/usr/bin/git -C "$LLAMA_SOURCE" rev-parse HEAD) = "$REVISION" ]] || fail 'Wrong llama.cpp source revision.'
[[ -z $(/usr/bin/git -C "$LLAMA_SOURCE" status --porcelain --untracked-files=all) ]] || fail 'llama.cpp checkout must be clean.'
licenses_source="$CURRENT_ASSETS/Contents/Resources/Licenses"
for name in Qwen-model-provenance.txt llama.cpp-LICENSE.txt THIRD_PARTY_NOTICES.md; do
  [[ -r "$licenses_source/$name" && -f "$licenses_source/$name" ]] || fail "Missing license: $name"
done
/usr/bin/cmp "$MACPILOT_SOURCE/THIRD_PARTY_NOTICES.md" "$licenses_source/THIRD_PARTY_NOTICES.md" || fail 'Asset notices are stale.'
[[ -r "$CURRENT_ASSETS/Contents/Resources/Models/$MODEL" ]] || fail 'Existing Qwen model is missing.'
# Discard injected compiler, SDK, CMake toolchain, preload and package-search settings.
# Only the explicitly selected tools and existing pinned source are inputs.
export LLAMA_SOURCE RUNTIME_BUILD CANDIDATE_ASSETS CURRENT_ASSETS MACPILOT_SOURCE DEVELOPER_DIR CMAKE
if [[ ${MACPILOT_CLEAN_ENV:-} != 1 ]]; then
  exec /usr/bin/env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    HOME="$HOME" TMPDIR=/tmp MACPILOT_CLEAN_ENV=1 \
    LLAMA_SOURCE="$LLAMA_SOURCE" RUNTIME_BUILD="$RUNTIME_BUILD" \
    CANDIDATE_ASSETS="$CANDIDATE_ASSETS" CURRENT_ASSETS="$CURRENT_ASSETS" \
    MACPILOT_SOURCE="$MACPILOT_SOURCE" DEVELOPER_DIR="$DEVELOPER_DIR" CMAKE="$CMAKE" RUNTIME_PROFILE="$RUNTIME_PROFILE" \
    /bin/bash "$0"
fi
# Reject bypassing the clean environment with injected flags.
for name in CFLAGS CXXFLAGS CPPFLAGS LDFLAGS SDKROOT MACOSX_DEPLOYMENT_TARGET CMAKE_TOOLCHAIN_FILE CMAKE_PROJECT_INCLUDE CMAKE_PROJECT_TOP_LEVEL_INCLUDES; do
  [[ -z "${!name:-}" ]] || fail "Unexpected environment override: $name"
done
[[ $("$CMAKE" --version | /usr/bin/head -n 1) = 'cmake version 3.31.8' ]] || fail 'Requires CMake 3.31.8.'
[[ $(/usr/bin/xcodebuild -version | /usr/bin/head -n 1) = 'Xcode 15.2' ]] || fail 'Requires selected Xcode 15.2.'
/usr/bin/xcrun --find clang >/dev/null
/usr/bin/xcrun --find clang++ >/dev/null
/usr/bin/xcrun --sdk macosx --show-sdk-path >/dev/null
printf 'Preparing candidate only: llama.cpp %s; profile %s; build concurrency 2.\n' "$REVISION" "$RUNTIME_PROFILE"
# mkdir, not mkdir -p: refuse an output created after preflight. Never remove outputs.
/bin/mkdir "$RUNTIME_BUILD"
/bin/mkdir "$CANDIDATE_ASSETS"
{
  printf 'Source revision: %s; profile: %s\n' "$REVISION" "$RUNTIME_PROFILE"
  "$CMAKE" --version
  /usr/bin/xcodebuild -version
  /usr/bin/xcrun clang --version
  /usr/bin/xcrun --sdk macosx --show-sdk-version
  printf 'Candidate only; unqualified for hardware compatibility or distribution.\n'
} > "$RUNTIME_BUILD/provenance.txt"
# Fresh cache, network fetching disabled, fixed Apple system tools, no presets.
"$CMAKE" -S "$LLAMA_SOURCE" -B "$RUNTIME_BUILD" -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=x86_64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.7 \
  -DCMAKE_OSX_SYSROOT="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)" \
  -DCMAKE_C_COMPILER="$(/usr/bin/xcrun --find clang)" \
  -DCMAKE_CXX_COMPILER="$(/usr/bin/xcrun --find clang++)" \
  '-DCMAKE_C_FLAGS=-march=x86-64 -mtune=generic' \
  '-DCMAKE_CXX_FLAGS=-march=x86-64 -mtune=generic' \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  '-DCMAKE_INSTALL_RPATH=@loader_path' \
  -DBUILD_SHARED_LIBS=ON -DGGML_STATIC=OFF \
  -DGGML_NATIVE=OFF -DGGML_CPU=ON -DGGML_CPU_ALL_VARIANTS=OFF \
  -DGGML_BACKEND_DL=OFF -DGGML_LTO=OFF \
  -DGGML_SSE42="$ISA" -DGGML_AVX="$ISA" -DGGML_AVX2="$ISA" \
  -DGGML_F16C="$ISA" -DGGML_FMA="$ISA" -DGGML_BMI2="$ISA" \
  -DGGML_AVX_VNNI=OFF -DGGML_AVX512=OFF \
  -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF \
  -DGGML_AVX512_BF16=OFF \
  -DGGML_AMX_TILE=OFF -DGGML_AMX_INT8=OFF -DGGML_AMX_BF16=OFF \
  -DGGML_ACCELERATE=ON -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=Apple \
  -DGGML_LLAMAFILE=ON -DGGML_CPU_REPACK=ON \
  -DGGML_OPENMP=OFF -DGGML_OPENMP_FETCH=OFF \
  -DGGML_METAL=OFF -DGGML_METAL_EMBED_LIBRARY=OFF \
  -DLLAMA_BUILD_COMMON=ON -DLLAMA_BUILD_TOOLS=ON \
  -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF -DLLAMA_BUILD_APP=OFF \
  -DLLAMA_BUILD_UI=OFF -DLLAMA_USE_PREBUILT_UI=OFF \
  -DLLAMA_CONNECT=OFF -DLLAMA_OPENSSL=OFF \
  -DLLAMA_SUBPROCESS=ON -DLLAMA_LLGUIDANCE=OFF \
  -DLLAMA_BUILD_MTMD=OFF -DLLAMA_USE_SYSTEM_GGML=OFF \
  -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
  -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
  -DFETCHCONTENT_UPDATES_DISCONNECTED=ON \
  -DLLAMA_BUILD_BORINGSSL=OFF -DLLAMA_BUILD_LIBRESSL=OFF \
  2>&1 | /usr/bin/tee "$RUNTIME_BUILD/configure.log"

# Validate actual generated commands BEFORE compiling. Do not trust cache labels alone.
/usr/bin/python3 - "$RUNTIME_BUILD" "$RUNTIME_PROFILE" <<'PY_FLAGS'
import json, re, shlex, sys
from pathlib import Path
root=Path(sys.argv[1])
log=(root/'configure.log').read_text()
# FetchContent is conditional on disabled SSL dependencies at this pinned revision.
# Keep offline flags as defense in depth, allowing only their verified unused warning.
allowed_unused={'FETCHCONTENT_FULLY_DISCONNECTED','FETCHCONTENT_UPDATES_DISCONNECTED'}
unused=set()
for section in log.split('Manually-specified variables were not used by the project:')[1:]:
 names=[]
 for line in section.splitlines():
  if not line.strip():
   continue
  if re.fullmatch(r'    [A-Za-z_][A-Za-z0-9_]*',line):
   names.append(line.strip())
  else:
   break
 assert names, 'Unrecognized unused-variable warning format'
 unused.update(names)
assert unused <= allowed_unused, 'Unexpected unused CMake settings: '+', '.join(sorted(unused-allowed_unused))
assert not re.search(r'(?i)fetching|downloading|performing download',log), 'Unexpected dependency acquisition'
cache=(root/'CMakeCache.txt').read_text()
for setting,value in [('GGML_NATIVE','OFF'),('CMAKE_OSX_ARCHITECTURES','x86_64'),('CMAKE_OSX_DEPLOYMENT_TARGET','13.7')]:
 assert re.search(r'^'+setting+r':[^=]+='+re.escape(value)+r'$',cache,re.M), setting
profile=sys.argv[2]
assert profile in ['sse2','avx2']
expected='ON' if profile=='avx2' else 'OFF'
for setting in ['GGML_SSE42','GGML_AVX','GGML_AVX2','GGML_F16C','GGML_FMA','GGML_BMI2']:
 assert re.search(r'^'+setting+r':[^=]+='+expected+r'$',cache,re.M), setting
isa_flags={'-msse4.2','-mavx','-mavx2','-mf16c','-mfma','-mbmi2'}
commands=json.loads((root/'compile_commands.json').read_text())
assert commands, 'Missing compile commands'
cpu_commands=0
for entry in commands:
 args=entry.get('arguments') or shlex.split(entry['command'])
 assert '-march=x86-64' in args and '-mtune=generic' in args, 'Missing baseline'
 is_cpu=any('CMakeFiles/ggml-cpu.dir/' in arg for arg in args)
 if is_cpu:
  cpu_commands+=1
  if profile=='avx2':
   assert isa_flags <= set(args), 'Optimized CPU flags missing'
 allowed={'-march=x86-64','-mtune=generic','-m64','-mmacosx-version-min=13.7'}
 if profile=='avx2' and is_cpu:
  allowed.update(isa_flags)
 for arg in args:
  if arg.startswith('-m'):
   assert arg in allowed, 'Unexpected CPU flag: '+arg
  assert arg not in ['-Xclang','-Xarch_x86_64'], 'Unreviewed compiler passthrough'
assert cpu_commands, 'CPU compilation records missing'
assert not re.search(r'-(?:march|mcpu|mtune)=native',json.dumps(commands)), 'Host-specific tuning'
print('Generated compiler flags passed baseline checks.')
PY_FLAGS
"$CMAKE" --build "$RUNTIME_BUILD" --target llama-completion --parallel 2 \
  2>&1 | /usr/bin/tee "$RUNTIME_BUILD/build.log"
helpers="$CANDIDATE_ASSETS/Contents/Helpers/LocalAI"
licenses="$CANDIDATE_ASSETS/Contents/Resources/Licenses"
models="$CANDIDATE_ASSETS/Contents/Resources/Models"
/bin/mkdir -p "$helpers" "$licenses" "$models"
for name in llama-completion libllama-completion-impl.dylib libllama-common.0.dylib \
  libllama.0.dylib libggml.0.dylib libggml-base.0.dylib libggml-cpu.0.dylib libggml-blas.0.dylib; do
  [[ -f "$RUNTIME_BUILD/bin/$name" ]] || fail "Missing build output: $name"
  /bin/cp -L -n "$RUNTIME_BUILD/bin/$name" "$helpers/$name"
  /usr/bin/cmp "$RUNTIME_BUILD/bin/$name" "$helpers/$name"
done
# Validate load commands without executing candidate binaries or changing signatures.
/usr/bin/python3 - "$helpers" <<'PY_LIBS'
from pathlib import Path
import subprocess,re,sys
root=Path(sys.argv[1]);names={p.name for p in root.iterdir()}
for p in root.iterdir():
 assert subprocess.check_output(['/usr/bin/lipo','-archs',str(p)],text=True).strip()=='x86_64', p.name
 text=subprocess.check_output(['/usr/bin/otool','-l',str(p)],text=True)
 paths=re.findall(r'cmd LC_RPATH\s+cmdsize \d+\s+path (.*?) \(offset',text)
 assert paths and set(paths)=={'@loader_path'}, (p.name,paths)
 minimum=re.findall(r'cmd LC_VERSION_MIN_MACOSX\s+cmdsize \d+\s+version ([0-9.]+)',text)
 minimum+=re.findall(r'cmd LC_BUILD_VERSION\s+cmdsize \d+\s+platform \d+\s+minos ([0-9.]+)',text)
 assert minimum, 'Missing minimum OS: '+p.name
 for v in minimum:
  parts=[int(x) for x in v.split('.')];parts += [0]*(3-len(parts))
  assert tuple(parts)<= (13,7,0), (p.name,v)
 deps=subprocess.check_output(['/usr/bin/otool','-L',str(p)],text=True).splitlines()[1:]
 for line in deps:
  dep=line.strip().split(' (compatibility',1)[0]
  if dep.startswith('@rpath/'):
   assert dep[len('@rpath/'):] in names, 'Unbundled dependency: '+dep
  else:
   assert dep.startswith(('/usr/lib/','/System/Library/')), 'Nonportable dependency: '+dep
 print('Verified helper layout/load commands:',p.name)
PY_LIBS
# Copy every existing license file byte-for-byte; no edits or replacements of inputs.
for file in "$licenses_source/"*; do
  [[ -f "$file" ]] || fail 'License directory contains a non-file; review before packaging.'
  /bin/cp -n "$file" "$licenses/"
  /usr/bin/cmp "$file" "$licenses/${file##*/}"
done
/usr/bin/cmp "$MACPILOT_SOURCE/THIRD_PARTY_NOTICES.md" "$licenses/THIRD_PARTY_NOTICES.md"
# Clone only: stop on unsupported storage rather than silently duplicating a GB model.
/bin/cp -c -n "$CURRENT_ASSETS/Contents/Resources/Models/$MODEL" "$models/$MODEL" || fail 'APFS model clone failed; no full-copy fallback is authorized.'
actual=$(/usr/bin/shasum -a 256 "$models/$MODEL")
[[ ${actual%% *} = "$MODEL_SHA" ]] || fail 'Qwen model hash mismatch.'
/usr/bin/shasum -a 256 "$helpers/"* "$licenses/"* > "$RUNTIME_BUILD/candidate-sha256.txt"
printf '%s\n' "$actual" >> "$RUNTIME_BUILD/candidate-sha256.txt"
# Candidate executable is deliberately NOT run. No inference, signing, or app build.
printf 'Candidate staged at %s\nBuild records at %s\n' "$CANDIDATE_ASSETS" "$RUNTIME_BUILD"
printf 'UNVALIDATED: next perform bounded startup, oldest-target hardware, RAM/latency and app checks from RUNTIME_BUILD.md.\n'
printf 'Keep logs/manifests local: they may contain machine-specific paths. Working assets remain unchanged.\n'
