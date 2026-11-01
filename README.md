# MacPilot

MacPilot is a native macOS assistant that uses local Qwen inference to turn requests into validated application-launch plans. It has a SwiftUI interface and an optional menu bar assistant.

**v0.1.0-alpha is a source-release milestone. A signed, notarized, downloadable MacPilot release is not available yet.** The Xcode project's marketing version remains `1.0`; binary release metadata has not yet been aligned with the alpha milestone.

Original MacPilot code: Copyright (c) 2026 RetroByteLab, under the [MIT License](LICENSE). Third-party components retain their own licenses; see [Third-Party Notices](THIRD_PARTY_NOTICES.md).

## Implemented features

The current source implements:

- Local Qwen2.5-1.5B-Instruct inference using the Q4_K_M GGUF model and llama.cpp.
- A native SwiftUI window and an optional menu bar assistant, disabled by default.
- Launching and activating installed applications through macOS application services.
- Preferred browser selection for supported browser requests.
- Multi-application commands, with one to five validated actions per plan.
- Installed-app resolution, ambiguous-installation handling, target identity checks, and review of unfamiliar applications.

Direct commands can be handled without Qwen. The source permits automatic execution for validated built-in shortcuts and previously approved installations. End-to-end automatic dispatch remains unverified; the test limitations below apply to both the original and experimental runtimes.

## macOS and hardware requirements

- **Configured minimum:** macOS Ventura 13.7. The verification machine ran macOS 13.7.8.
- **Current local AI:** native Intel `x86_64` only. Apple Silicon and execution under Rosetta are rejected for bundled AI.
- **Verified hardware:** one Intel Core i7-7660U machine. Other Intel Macs, including the oldest intended targets, have not been qualified.
- **Required CPU/OS checks:** AVX and AVX2, F16C, FMA, BMI2, SSE4.2, POPCNT, XSAVE/OSXSAVE, and macOS-enabled AVX support. The gate also checks the earlier SSE3, SSSE3, and SSE4.1 features used by the baseline.

The current [CPU compatibility gate](MacPilot/MacPilot/ContentView.swift) reads bounded macOS sysctl values before runtime startup or inference. Missing, malformed, or uncertain information rejects local AI compatibility. The assessment is cached lazily; it does not poll or launch a detection process. Application-launch routing is separate from the local AI gate.

These checks are a known minimum, not proof that every Intel Mac with those flags can execute the original runtime. That runtime was compiled with host-dependent tuning, and its complete instruction requirements have not been established. OS version, CPU brand, or AVX2 alone is insufficient evidence of compatibility. Full-app minimum RAM requirements have not been qualified.

## Original and experimental runtimes

The development app still uses the **original runtime**. The SSE2 and explicit AVX2 candidates have not replaced it.

| Runtime | Build configuration | Current status |
| --- | --- | --- |
| Original | llama.cpp `0.8.0-dev`, ggml `0.28.0`; `GGML_NATIVE=ON`, `-march=native` | Retained in the current verified AI assets; full historical reproducibility and cross-Mac compatibility remain unresolved. |
| Experimental AVX2 | `GGML_NATIVE=OFF`, explicit AVX/AVX2, F16C, FMA, BMI2 and SSE4.2; generic tuning | Compiled and tested on the verification machine. Performance was close to the original, but a raw-model refusal regression remains. |
| Experimental SSE2 | `GGML_NATIVE=OFF`, explicit x86-64/SSE2 baseline with optional extensions disabled | Compiled and tested on the same machine; substantially slower in the sampled inference tests. Other hardware remains untested. |

**Automatic runtime switching is not implemented.** The app uses one helper directory and does not select a candidate automatically. The SSE2 candidate does not currently enable an older-Mac fallback: the app's existing AI gate still requires the AVX2 feature contract. Do not overwrite working assets or mix libraries from different runtime builds.

Both candidate builds use the pinned llama.cpp revision `5047748f114564fcf271e6a648f60e2d2eae6264`. The original bundle's local build records corroborate that revision, but a clean reconstruction of its historical build and packaging process has not been completed.

## External AI assets

Source downloads **exclude the large Qwen model, compiled runtime binaries, build products, and generated MacPilot.app**. The Xcode build neither downloads these assets nor compiles llama.cpp automatically.

Supply the exact Qwen2.5-1.5B-Instruct Q4_K_M GGUF expected by the source and a complete, compatible prepared Intel runtime. The model alone is approximately 1.12 GB. Its filename, byte count, and SHA-256 are pinned in [ContentView.swift](MacPilot/MacPilot/ContentView.swift), with publisher provenance in [Third-Party Notices](THIRD_PARTY_NOTICES.md).

The runtime executable must match the command-line interface used by MacPilot and must have its matching libraries. Renaming an arbitrary llama.cpp executable is insufficient. There is currently no public prebuilt MacPilot asset download or fully verified recipe for recreating the original host-tuned bundle. Candidate preparation is described separately below.

Keep the asset directory outside the source repository. It may be an existing prepared app bundle or another directory with this app-style layout:

```text
<AI_ASSET_ROOT>/
└── Contents/
    ├── Helpers/
    │   └── LocalAI/
    │       ├── llama-completion
    │       ├── libllama-completion-impl.dylib
    │       ├── libllama-common.0.dylib
    │       ├── libllama.0.dylib
    │       ├── libggml.0.dylib
    │       ├── libggml-cpu.0.dylib
    │       ├── libggml-blas.0.dylib
    │       └── libggml-base.0.dylib
    └── Resources/
        ├── Models/
        │   └── qwen2.5-1.5b-instruct-q4_k_m.gguf
        └── Licenses/
            ├── Qwen-model-provenance.txt
            ├── llama.cpp-LICENSE.txt
            └── THIRD_PARTY_NOTICES.md
```

All files must be readable, and `llama-completion` must be executable. Keep runtime libraries together with portable loader paths. Copy the current root `THIRD_PARTY_NOTICES.md` into the external license directory unchanged, alongside the existing provenance and llama.cpp license. The root Markdown file is not copied directly by the project; the build copies the external license files.

`MACPILOT_LOCAL_AI_BUNDLE` names the asset root **above `Contents`**, not the model or helper subdirectory. It defaults to `$(SRCROOT)`, the inner `MacPilot` directory containing the Xcode project. A source-only checkout lacks the required assets there, so pass an explicit external root.

The build checks the model, executable, required libraries, and the two existing license/provenance files. Its declared outputs now include `THIRD_PARTY_NOTICES.md`; supply all three license files shown above. Runtime validation additionally checks the model size/hash, binary architecture, and runtime startup.

## Build the macOS app

Use **Xcode 15.2** with its included macOS SDK selected for the build. Xcode 12.4 is insufficient. Select the installed Xcode 15.2 developer directory in your environment if the system default points elsewhere; no particular installation path is assumed.

Run from the repository root. Replace `<AI_ASSET_ROOT>` with the absolute path to the complete prepared assets, and `<BUILD_DIR>` with a dedicated external DerivedData directory:

```sh
xcodebuild \
  -project MacPilot/MacPilot.xcodeproj \
  -scheme MacPilot \
  -configuration Debug \
  -derivedDataPath "<BUILD_DIR>" \
  clean build \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS=x86_64 \
  MACPILOT_LOCAL_AI_BUNDLE="<AI_ASSET_ROOT>"
```

This parameterized configuration passed a clean Intel Debug build with Xcode 15.2 and the verified original AI assets. It retains Xcode's script sandbox. Signing is disabled only by the command-line override for local build verification; this command does not produce a signed or notarized distribution release. The app output is `<BUILD_DIR>/Build/Products/Debug/MacPilot.app`.

The `Bundle Local AI` phase runs on every build, copies the helpers, model and license files, and uses APFS cloning for the model when available. The verified clean build included the notices and preserved the supplied AI files byte-for-byte. Missing assets produce setup guidance; an invalid asset-root directory can also be rejected by Xcode input validation. Keep script sandboxing enabled and declare any future generated outputs explicitly.

After packaging, resource lookup is relative to `Bundle.main.bundleURL`. The builder's external asset directory is not needed by that app bundle. A source-only fresh-clone setup has not been independently reproduced on another developer's Mac.

## Experimental runtime builder

[build-intel-runtime.sh](build-intel-runtime.sh) prepares candidate assets in new external directories from an already available, clean checkout at the pinned llama.cpp revision. It requires native Intel macOS, Xcode 15.2, CMake 3.31.8, and an existing complete AI asset root. It does not fetch the source, install dependencies, download a model, replace working assets, run inference, or build MacPilot.app.

Before invoking it, set these environment variables to absolute paths:

- `LLAMA_SOURCE`: clean pinned llama.cpp checkout.
- `RUNTIME_BUILD`: new external build directory.
- `CANDIDATE_ASSETS`: new external app-style asset directory.
- `CURRENT_ASSETS`: existing verified asset root supplying Qwen and license files.
- `MACPILOT_SOURCE`: this repository root.
- `DEVELOPER_DIR`: the selected Xcode 15.2 developer directory.
- `CMAKE`: the CMake 3.31.8 executable.

The output directories must not exist; their parent directories must already exist. They must be separate from each other, this repository, the llama.cpp source, and working assets. After reviewing the script and setting those inputs, choose one profile:

```sh
# Default conservative candidate:
RUNTIME_PROFILE=sse2 /bin/bash build-intel-runtime.sh

# Alternative explicit AVX2 candidate, using different fresh output directories:
RUNTIME_PROFILE=avx2 /bin/bash build-intel-runtime.sh
```

The script keeps `GGML_NATIVE=OFF`, uses `-march=x86-64 -mtune=generic`, validates generated CPU flags, and limits compilation to two jobs. It stages the eight helpers, checks architecture and load paths, preserves license files, and clones the existing Qwen model on APFS rather than silently making a full-copy fallback. It refuses stale notices and existing output directories. It does not contain a thermal monitor; the controlled verification runs used an external memory/thermal monitor. Stop a build if resource pressure becomes excessive.

See [RUNTIME_BUILD.md](RUNTIME_BUILD.md) for the source-checked recipe and compatibility/resource validation gates. That document records the earlier SSE2 plan and contains historical status text predating the successful candidate builds. The current script implements both profiles; neither profile is an approved replacement, and cross-machine or byte-for-byte reproducibility has not been established.

## Verification and known limitations

- The clean Xcode 15.2 Intel Debug build passed after declaring the generated notices output. This verifies compilation and packaging, not complete app behavior.
- Seventy focused CPU checks passed. Sixty captured command replays matched pre-gate results; that is a regression comparison, not 60 successful end-to-end commands.
- A 30-command comparison produced valid JSON for all 30 inputs in each runtime. Raw-model target accuracy was 22/30 for the original and 21/30 for the explicit AVX2 candidate. Plan validation and the separately invoked mock executor passed 28/30 for each.
- Fifteen automatic cases per runtime required a test-only executor bridge. Automatic dispatch remains unverified in that standalone harness. Mock launchers performed no real application-control actions.
- The AVX2 candidate's refusal regressed on “Get things ready,” confirmed by a focused repeat. The direct router blocks that request before Qwen. Both runtimes failed shared coding/research expectations, including a six-app plan rejected by the five-action limit.
- Samples do not prove universal accuracy, absence of unsupported instructions on other CPUs, or reliable execution on untested Macs. Original-runtime provenance, full reproducibility, older-hardware qualification, and end-to-end menu bar/launch behavior still need verification.
- Automation is limited to supported app-launch plans, not general scripting or arbitrary app control. Requests are limited to 500 characters and plans to five actions. Missing or ambiguous targets can prevent execution.
- The current inference settings retain Qwen Q4, two generation/batch threads, bounded context and batching, offline operation, and automatic mmap behavior when supported. No forced model page locking is requested. Inference can stop under serious thermal pressure or after the app's timeout.
- Distribution signing, notarization, release-version metadata, and binary-release preparation remain separate work. The clean build reported an existing deprecated application-lookup API warning.

## Security and privacy

Inference uses the bundled executable in offline mode. The request and a bounded list of installed application names are supplied to that local process; this inference path does not use a cloud model. Applications launched by the user retain their own network behavior.

Model output is treated as a proposed plan and validated for supported action structure, app names, installed targets, ambiguity, and identity before launching. Familiar shortcuts and previously approved installations are eligible for automatic execution in the source; unfamiliar targets require review. The automatic-dispatch verification limit above remains applicable. macOS permission checks and sandbox restrictions remain in place.

Local preferences retain settings and approved application identities/paths. The interface retains the current request and plan in memory. Local inference does not make model suggestions infallible.

## Third-party components and releases

Credit to the Qwen team for Qwen2.5-1.5B-Instruct, and to the llama.cpp/ggml authors and contributors for the inference runtime. The bundled runtime also incorporates separately attributed code, including Mozilla Foundation llamafile, nlohmann/json, cpp-httplib, and sheredom subprocess code.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for exact sources, the Apache 2.0 and MIT texts, public-domain dedications, and remaining provenance limitations. Some historical packaging-status paragraphs predate the verified notice synchronization; always package the current root notice as shown above. This README does not declare complete distribution-license compliance.

The source repository supplies MacPilot code and documentation under their stated terms, with external AI assets required for an app build. A future downloadable release is intended to include Qwen Q4 and the runtime inside MacPilot.app. No signed/notarized installer, public download link, or release availability is promised here.

## Screenshots

Screenshots will be added after the alpha interface is reviewed for publication.
