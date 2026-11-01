# Intel runtime builds and verification

The original runtime remains in MacPilot's working AI assets. **Separate SSE2 and explicit AVX2 candidates have compiled and undergone controlled testing; both remain experimental.** Neither candidate has replaced the original, and automatic runtime switching is not implemented.

Earlier versions of this document described an unexecuted SSE2 plan. That status is superseded by the results below. Successful local candidate builds do not establish compatibility with other Macs, complete accuracy equivalence, or byte-for-byte reproducibility.

## Pinned inputs and provenance

- Upstream source: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp).
- Pinned revision: [`5047748f114564fcf271e6a648f60e2d2eae6264`](https://github.com/ggml-org/llama.cpp/tree/5047748f114564fcf271e6a648f60e2d2eae6264).
- Generated versions: llama.cpp `0.8.0-dev`, ggml `0.28.0`. Local build number `1` is not an upstream release tag.
- Original local build records: CMake 3.31.8, Unix Makefiles, AppleClang `12.0.0.12000032`, Release, shared libraries, CPU/Apple Accelerate/BLAS, llamafile enabled, OpenMP and Metal disabled.
- Candidate build records: CMake 3.31.8, Xcode 15.2 (`15C500b`), AppleClang `15.0.0.15000100`, macOS SDK 14.2, Release, explicit `x86_64`, and deployment target macOS 13.7.

All eight original packaged helpers matched their local-build UUIDs and machine-code sections. The local source checkout was clean at the recorded revision. Original packaging changed absolute build rpaths to `@loader_path`; a complete historical packaging script or patch record was not recovered. This evidence corroborates provenance but does not reconstruct every historical input or transformation.

The candidate builds used the clean pinned source and fresh external build/output directories. Generated commands, caches, provenance text, and helper/model hashes were retained locally. Logs can contain machine-specific paths and must be reviewed before publication. No private paths are required by the recipe below.

## Runtime configurations

| Setting | Original working runtime | Experimental SSE2 | Experimental AVX2 |
| --- | --- | --- | --- |
| Architecture | Intel `x86_64` | Intel `x86_64` | Intel `x86_64` |
| Native tuning | `GGML_NATIVE=ON`; `-march=native` | `GGML_NATIVE=OFF` | `GGML_NATIVE=OFF` |
| Explicit compiler baseline | Host-dependent | `-march=x86-64 -mtune=generic` | `-march=x86-64 -mtune=generic` |
| SSE4.2 / AVX / AVX2 / F16C / FMA / BMI2 options | Individual cache entries were OFF, but native tuning enabled host instructions | All OFF | All ON for the CPU backend |
| CPU / Accelerate / Apple BLAS / llamafile | ON | ON | ON |
| Shared libraries | ON | ON | ON |
| OpenMP / Metal | OFF | OFF | OFF |
| Dynamically loaded CPU variants / LTO | Not used in the recorded build | OFF | OFF |
| Status | Retained; historical reproduction incomplete | Built and staged separately | Built and staged separately |

The pinned `ggml/src/ggml-cpu/CMakeLists.txt` appends `-march=native` in its native branch. With native tuning disabled, its individual feature options add `-msse4.2`, `-mavx`, `-mavx2`, `-mf16c`, `-mfma`, and `-mbmi2`. Disabling native tuning alone is insufficient unless those options and generated commands are inspected too.

AVX2, F16C, and BMI2 instructions were observed in the original CPU library. An attempted full inspection with the older disassembler exhausted memory, so the original instruction inventory is incomplete. A bounded inspection of the candidate's Q4 dot-product function confirmed AVX2 and FMA instructions. The candidate's explicit compiler configuration also enables F16C, BMI2, SSE4.2 and POPCNT, with their earlier SSE prerequisites. No candidate uses host-specific tuning or enables AVX-512/AMX.

The original helpers reported minimum macOS 11.1 load commands, while the **app's configured minimum remains macOS 13.7**. This does not qualify older macOS versions or older Intel hardware. Candidate structure checks verified Intel architecture, deployment compatibility, matching dependencies, portable rpaths, and executable startup on the test machine.

## Measured results

Measurements used one Intel Core i7-7660U machine running macOS 13.7.8. These are isolated runtime-process measurements, not full-app memory requirements or a minimum supported hardware specification. The same existing Qwen Q4 model, prompts, schema, and inference settings were used for each paired comparison. Runtimes ran sequentially with resource monitoring; the 30-command suite alternated runtime order and included pauses/cooling intervals. Thermal state stayed at or below fair, without pressure-stop events or runtime crashes.

### Thirty-command original versus AVX2 comparison

| Measure | Original | Experimental AVX2 |
| --- | ---: | ---: |
| Median generation speed | **14.08 tokens/s** | **14.76 tokens/s** |
| Median total response | 7.13 s | 7.04 s |
| Maximum observed peak RSS | 1.656 GiB | 1.658 GiB |
| Valid JSON | 30/30 | 30/30 |
| Raw-model target accuracy | 22/30 | 21/30 |
| Plan validation and separately invoked mock executor | 28/30 | 28/30 |

The observed peak-RSS difference was small; this sample does not establish a universal memory or performance bound. Initialization was not isolated: runtime-reported load time includes prompt-processing work in these records. Do not interpret it as a clean measurement of model initialization alone. Cache state, foreground workload, prompt length, and generated token count can affect timing.

### Earlier matched three-prompt comparison

SSE2 was not included in the later 30-command suite. Its approximately **3 tokens/s** result comes from this smaller, earlier comparison:

| Measure | Original | SSE2 | AVX2 |
| --- | ---: | ---: | ---: |
| Generation range | 10.82–13.11 tokens/s | 2.61–3.42 tokens/s | 13.21–14.10 tokens/s |
| Median generation | 12.88 tokens/s | **3.09 tokens/s** | 13.88 tokens/s |
| Median total response | 7.06 s | 14.74 s | 5.40 s |
| Maximum observed peak RSS | 1.653 GiB | **1.073 GiB** | 1.653 GiB |
| Correct sampled plans | 3/3 | 3/3 | 3/3 |

The original/AVX2 medians in this table differ from the 30-command medians because the test cohorts and run conditions differ. SSE2 used less resident memory in these samples but was substantially slower. Neither result justifies replacing the current runtime or claiming support for untested Macs.

## Accuracy and test boundaries

The 30 commands covered single/multiple applications, browser requests, ambiguous instructions, nonexistent apps, exclusions, unsupported actions, and purpose-based requests. Every command was also forced through raw inference for comparison, even where MacPilot normally routes or rejects it before Qwen.

- **One AVX2 raw-model regression:** for “Get things ready,” the original returned no actions and AVX2 proposed six apps. A focused repeat reproduced the difference. The direct router rejects this phrase before inference, and the decoder also rejects more than five actions; there was no new failure in the tested routed-plan layer.
- **Shared failures:** both runtimes proposed six apps for the coding request and omitted a browser for the research request. Both therefore passed 28/30 plan/mock-executor checks. Valid JSON does not imply a correct or executable plan.
- **Automatic dispatch remains unverified:** fifteen eligible automatic cases per runtime required a test-only bridge that explicitly invoked the existing gated executor. Mock launchers performed no real application-control actions. The 28/30 figure is not an end-to-end automatic-execution success rate.
- Seventy focused CPU compatibility checks passed. Sixty captured command replays matched pre-gate behavior; this establishes no change from that baseline, not sixty successful commands.

Changing kernels can change floating-point results and selected tokens even with unchanged model weights and temperature zero. Identical examples do not prove universal accuracy equivalence. Keep the original runtime while investigating the refusal regression, shared planning failures, and dispatch behavior.

## CPU and OS compatibility checks

The current [ContentView.swift](MacPilot/MacPilot/ContentView.swift) gate requires native Intel execution and confirms:

- Kernel capability values for AVX, AVX2, F16C, FMA, BMI2 and SSE4.2.
- POPCNT, XSAVE, OSXSAVE, AVX1.0, F16C, FMA, SSE3, SSSE3, SSE4.1 and SSE4.2 in the basic feature report.
- AVX2 and BMI2 in the leaf-7 feature report.

It uses bounded `sysctlbyname` reads, exact enabled values, and strict feature-list parsing. Missing, false, malformed or uncertain replies reject compatibility before resource startup/probing or inference. Kernel-enabled AVX is checked rather than trusting a hardware bit alone. The assessment is lazy and cached; it adds no background polling or detection subprocess. The detector itself executes no CPUID/XGETBV or AVX-specific instruction.

A separate baseline-built test independently confirmed CPUID flags, OSXSAVE, and XCR0 SSE/AVX state on the verification machine (`XCR0=7`). That test is evidence about this host, not a helper integrated into the app or proof about other machines.

The app still uses one `Contents/Helpers/LocalAI` directory and the original asset configuration. **Automatic AVX2/SSE2 switching is not implemented.** The existing gate still requires the AVX2 contract even if someone manually supplies SSE2 helpers. A future selector must run baseline-safe detection before loading or probing optimized code, reject uncertain information, and keep each runtime's matching libraries isolated. Do not use an illegal-instruction crash as a feature probe.

The known gate does not certify every instruction in the original host-tuned binary. Older Intel Macs, other OS versions, Apple Silicon and Rosetta remain unqualified; Apple Silicon/Rosetta are rejected for current bundled AI. Do not infer compatibility from macOS version or AVX2 alone.

## Verified candidate build procedure

The canonical configure/build/staging commands are in [build-intel-runtime.sh](build-intel-runtime.sh). Both profiles have run successfully with Xcode 15.2, CMake 3.31.8 and the pinned source. The script remains candidate-only; successful execution does not approve replacement of working assets.

From the repository root, set these seven environment variables to absolute paths:

| Variable | Input or output |
| --- | --- |
| `LLAMA_SOURCE` | Already available clean checkout at the pinned revision |
| `CMAKE` | Existing CMake 3.31.8 executable |
| `DEVELOPER_DIR` | Existing Xcode 15.2 developer directory |
| `CURRENT_ASSETS` | Existing verified app-style assets supplying Qwen and license files |
| `MACPILOT_SOURCE` | This repository root |
| `RUNTIME_BUILD` | New external build directory |
| `CANDIDATE_ASSETS` | New external app-style asset directory |

Both output paths must be new, with existing parents, and must not overlap each other, the source checkout, this repository, or working assets. The script refuses existing outputs. Use different fresh outputs for each profile:

```sh
# All seven variables above must already be exported.
RUNTIME_PROFILE=sse2 /bin/bash build-intel-runtime.sh

# After selecting different, fresh RUNTIME_BUILD and CANDIDATE_ASSETS values:
RUNTIME_PROFILE=avx2 /bin/bash build-intel-runtime.sh
```

The default profile is `sse2`. Invalid profile names, wrong revisions, dirty source, missing tools/assets, stale notices, or overlapping outputs stop the script. It does not acquire source, install dependencies, download models, or launch candidate binaries. It sanitizes the compiler environment and uses a fresh CMake cache.

### Explicit build controls

Both profiles configure Release with `-march=x86-64 -mtune=generic`, `GGML_NATIVE=OFF`, deployment target 13.7, shared libraries, and portable install rpath `@loader_path`. `GGML_CPU`, `GGML_ACCELERATE`, Apple `GGML_BLAS`, `GGML_LLAMAFILE`, `GGML_CPU_REPACK`, `LLAMA_BUILD_COMMON`, `LLAMA_BUILD_TOOLS`, and `LLAMA_SUBPROCESS` remain enabled. Metal, OpenMP, dynamic CPU variants, LTO, AVX-512 and AMX remain disabled. Only the six explicit CPU feature options listed in the configuration table differ between profiles.

The standalone `llama-completion` target depends on `llama-completion-impl`, common and llama/ggml libraries; it does not require the unified app or server. Server, app, examples, tests, UI, prebuilt UI, connect, OpenSSL, BoringSSL, LibreSSL, LLGuidance, standalone MTMD and system ggml substitution are disabled. The underlying build command is:

```sh
"$CMAKE" --build "$RUNTIME_BUILD" --target llama-completion --parallel 2
```

The script inspects all generated compilation records before building. SSE2 permits only the explicit baseline; AVX2 permits the six feature flags only for CPU-backend commands. It rejects native/host tuning, missing required flags, unexpected CPU flags, and unreviewed passthroughs.

`FETCHCONTENT_FULLY_DISCONNECTED` and `FETCHCONTENT_UPDATES_DISCONNECTED` remain enabled as offline safeguards. At this revision FetchContent is conditional on disabled SSL dependency branches, so CMake reports those two variables as unused. Validation narrowly allows those two names and still rejects other unused settings. This replaces the original over-broad validation failure; warnings are not globally suppressed.

Compilation is limited to two jobs. The controlled runs also used an external thermal/memory monitor; **the build script itself has no thermal monitor**. Inspect resource pressure before starting, avoid concurrent inference, and stop on serious/critical thermal state or excessive memory pressure. Failed/partial candidate directories are retained for inspection, never substituted for working assets.

## Staging and load-path verification

The script copies these eight built helper files into `CANDIDATE_ASSETS/Contents/Helpers/LocalAI`, resolving version symlinks to regular files:

```text
llama-completion
libllama-completion-impl.dylib
libllama-common.0.dylib
libllama.0.dylib
libggml.0.dylib
libggml-base.0.dylib
libggml-cpu.0.dylib
libggml-blas.0.dylib
```

It uses `lipo` and `otool` to check x86_64 architecture, minimum OS compatibility, `@rpath` dependencies with matching bundled names, and `@loader_path` search paths. Absolute dependency paths are limited to macOS system libraries. The candidate rpath settings worked without a manual `install_name_tool` patch in the verified builds. Stop if future output violates this contract; do not introduce undocumented binary edits.

The script copies all existing license files byte-for-byte, checks that the current root notice matches the external copy, and APFS-clones the model into `Contents/Resources/Models`. A failed clone stops staging rather than silently making a full-copy fallback. It verifies the model SHA-256 and records hashes for helpers, licenses and model. It does not change working assets, assemble MacPilot.app, alter signing settings, or sign the candidate.

Retained build records include `provenance.txt`, `configure.log`, `build.log`, `compile_commands.json`, `CMakeCache.txt`, generated target/link commands, and `candidate-sha256.txt`. These local records can contain private filesystem information; publish only reviewed/redacted evidence.

For app packaging, follow the exact external-asset layout and Xcode 15.2 command in [README.md](README.md). A clean Intel Debug build with the **original** assets passed after explicitly declaring the notices output; script sandboxing stayed enabled. Candidate structural/startup tests are separate from app integration. The candidates have not been installed as the working app runtime.

## Qwen and resource invariants

Keep `qwen2.5-1.5b-instruct-q4_k_m.gguf` unchanged. Its pinned SHA-256 is:

```text
6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e
```

Keep the existing prompt/schema, offline mode, CPU-only inference (`-ngl 0`), two generation and batch threads (`-t 2 -tb 2`), context 1024, output limit 256, batch 64, microbatch 64, zero polling, no warmup and temperature zero. Retain `VECLIB_MAXIMUM_THREADS=1`, `OMP_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`.

The pinned common parameters use `LLAMA_LOAD_MODE_AUTO`; mmap is selected when supported. The app does not force mlock or disable mmap. Preserve this behavior and verify actual mapping/pressure during future hardware testing. Do not compensate for lower throughput by increasing concurrency, locking the full model in RAM, changing quantization, or silently changing batching.

## Third-party attribution and distribution notices

Credit to the Qwen team for the model and the llama.cpp/ggml authors and contributors for the runtime. The model is Apache 2.0 with the verified `Copyright 2024 Alibaba Cloud` attribution. llama.cpp/ggml use MIT; embedded code includes Mozilla Foundation llamafile (MIT), nlohmann/json (MIT), cpp-httplib (MIT), and sheredom subprocess code (public-domain dedication/Unlicense).

Preserve `Qwen-model-provenance.txt`, `llama.cpp-LICENSE.txt`, and the current root `THIRD_PARTY_NOTICES.md` in the supplied `Contents/Resources/Licenses` directory. See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for complete texts, exact sources, attribution, and unresolved provenance limits. The existing app build copies the external notice, not the root document directly. Further runtime/SDK changes require another dependency/notice review; no blanket distribution-license compliance is asserted. Original MacPilot code retains its [MIT license](LICENSE) under RetroByteLab.

## Remaining gates before integration or release

1. Investigate the repeated AVX2 refusal regression and shared coding/research failures with focused tests. Do not rerun the entire historical benchmark suite without a concrete reason.
2. Verify automatic dispatch in an appropriate app-level harness. The standalone executor bridge does not establish real automatic execution or menu bar/activation behavior.
3. Qualify explicitly selected older Intel Macs on supported macOS versions. Check every required CPU/OS feature before loading optimized code; test real model execution for illegal instructions or loader failures. Keep architecture checks separate from instruction-set qualification.
4. Repeat bounded RAM, cold/warm response, initialization and thermal measurements on target machines, preserving model and settings. Do not infer full-app RAM requirements from runtime peak RSS.
5. Rebuild in fresh external directories on another developer environment using recorded inputs. Explain timestamp, UUID, signature, toolchain and SDK differences before claiming byte reproducibility. The original historical build still lacks a complete independently reproduced recipe.
6. Design and test any future selector before packaging both isolated runtime/library sets. No switching is implemented by this document or the current script.
7. Complete remaining provenance and distribution checks, release metadata, signing and notarization separately. Keep working assets intact until replacement is explicitly approved.

The candidate build procedure is locally verified. Cross-machine reproducibility, oldest-target compatibility, complete accuracy equivalence, and a signed/notarized binary release remain unverified.
