# Third-Party Notices — MacPilot v0.1.0-alpha

This document attributes third-party components in the inspected development AI bundle and records outstanding distribution work. It does not select or grant a license for original MacPilot Swift code. It is not a declaration that downloadable releases are ready for distribution.

## Qwen model — Apache License 2.0

Credit: the Qwen team, publisher of **Qwen2.5-1.5B-Instruct-GGUF**. The pinned publisher LICENSE carries the exact attribution **Copyright 2024 Alibaba Cloud**.

- [Official GGUF repository](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF).
- [Pinned model card](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/blob/91cad51170dc346986eccefdc2dd33a9da36ead9/README.md), identifying the license as Apache-2.0 and the base model as Qwen2.5-1.5B-Instruct.
- [Base model repository](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct).
- Revision: `91cad51170dc346986eccefdc2dd33a9da36ead9`.
- Bundled artifact: `Contents/Resources/Models/qwen2.5-1.5b-instruct-q4_k_m.gguf`.
- SHA-256, recomputed from the actual bundled model: `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`.

Verified against the official publisher on 2026-10-31:

- [Pinned LICENSE](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/blob/91cad51170dc346986eccefdc2dd33a9da36ead9/LICENSE): Apache License 2.0, including `Copyright 2024 Alibaba Cloud` in its appendix. The full publisher text is reproduced below without substituting a different copyright holder.
- [Pinned model card](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/blob/91cad51170dc346986eccefdc2dd33a9da36ead9/README.md): declares `apache-2.0` and identifies the base model as Qwen2.5-1.5B-Instruct.
- [Revision file inventory](https://huggingface.co/api/models/Qwen/Qwen2.5-1.5B-Instruct-GGUF/revision/91cad51170dc346986eccefdc2dd33a9da36ead9?blobs=true): confirms the exact revision and model filename. Its LFS SHA-256 matches the previously recomputed bundled-model hash above. No separate NOTICE file, including any nested NOTICE path, is listed in that revision. No separate NOTICE is invented or required solely because the Apache license describes one conditionally.

The bundled `Qwen-model-provenance.txt` agrees with the model identity and revision but is not a full license and omits the publisher's copyright attribution. The earlier consolidated notice included the generic Apache appendix rather than the publisher's filled-in attribution; this source document corrects that omission.

Under Apache 2.0 section 4, give recipients a full license copy; identify modified files prominently; retain applicable copyright, patent, trademark, and attribution notices in distributed derivative source; and preserve relevant NOTICE attribution if upstream supplies one. Section 6 does not grant general trademark rights or imply endorsement. Preserve `Copyright 2024 Alibaba Cloud` with the model license. MacPilot uses the publisher's quantized artifact; no additional MacPilot model modification is asserted by this audit.

This verifies the licensing evidence for the pinned GGUF distribution, not all runtime dependencies. The Qwen correction has been synchronized to the external asset root and built app. Those copies remain unchanged in this task and must be refreshed separately for the new runtime notices below.

## llama.cpp and ggml — MIT

Credit: **The ggml authors**, with the exact notice in the inspected bundled license: `Copyright (c) 2023-2026 The ggml authors`.

- [Source repository](https://github.com/ggml-org/llama.cpp).
- [Inspected local source revision](https://github.com/ggml-org/llama.cpp/tree/5047748f114564fcf271e6a648f60e2d2eae6264).
- [License at that revision](https://github.com/ggml-org/llama.cpp/blob/5047748f114564fcf271e6a648f60e2d2eae6264/LICENSE).

The local source checkout and generated build metadata identify commit `5047748f114564fcf271e6a648f60e2d2eae6264`, llama version `0.8.0-dev`, ggml version `0.28.0`, and local build number `1`. The bundled common library contains short commit `5047748`; Mach-O ggml library versions report `0.28.0`. All eight bundled binaries also match the local build UUIDs and machine-code sections. The current source checkout is clean. Build records show Release, AppleClang 12, CPU/Accelerate/BLAS, llamafile, and `-march=native`. Packaged rpaths differ from the local build and use `@loader_path`. A complete packaging recipe, historical patch record, and clean rebuild comparison remain unavailable; reproducibility is not established. Build number `1` is not an upstream release tag; no official binary-release version is claimed.

The inspected `Contents/Helpers/LocalAI` contains:

| Component | Attribution / license |
| --- | --- |
| `llama-completion` | llama.cpp; MIT |
| `libllama-completion-impl.dylib` | llama.cpp; MIT |
| `libllama-common.0.dylib` | llama.cpp common code; MIT, plus embedded dependencies below |
| `libllama.0.dylib` | llama.cpp; MIT |
| `libggml.0.dylib` | ggml; MIT |
| `libggml-base.0.dylib` | ggml; MIT |
| `libggml-cpu.0.dylib` | ggml CPU backend; MIT, plus Mozilla llamafile MIT code below |
| `libggml-blas.0.dylib` | ggml BLAS backend; MIT |

Include the full MIT license and copyright notice with binary distributions. The existing `Contents/Resources/Licenses/llama.cpp-LICENSE.txt` contains that text; it is reproduced below.

## Embedded dependencies and system libraries

Dynamic dependencies were inspected with `otool -L`; source headers, CMake configuration, generated build metadata, and binary strings were also inspected. Dependencies compiled into a library can require notices even without a separate dylib.

| Component | Evidence / version | License and attribution |
| --- | --- | --- |
| [nlohmann/json](https://github.com/nlohmann/json) | Binary ABI symbols and vendored header identify 3.12.0 | MIT; `Copyright (c) 2013-2025 Niels Lohmann`. Full local `licenses/LICENSE-jsonhpp` reproduced below. |
| [cpp-httplib](https://github.com/yhirose/cpp-httplib) | Common target links it; binary strings and header identify 0.64.0 | MIT; local LICENSE says `Copyright (c) 2017 yhirose`; header additionally says `Copyright (c) 2026 Yuji Hirose. All rights reserved.` Retain both notices. Full local LICENSE reproduced below. |
| llamafile `sgemm.cpp` | CPU backend link command includes its object; bundled CPU library exports `llamafile_sgemm` | MIT; `Copyright 2024 Mozilla Foundation`. Full embedded notice below. |
| [sheredom subprocess.h](https://github.com/sheredom/subprocess.h) | Compiler dependencies include the header; bundled common library exports `subprocess_*` symbols | Public-domain dedication / Unlicense; full terms below. No separate version or copyright holder/year inferred. |
| llama.cpp `common/base64.hpp` | CMake lists it, but inspected shipped-target compiler dependencies do not; inclusion is unconfirmed | Public-domain dedication / Unlicense retained below as reference only. |
| Apple Accelerate, libSystem, libc++ | Linked at macOS system paths, not copied into the inspected helper directory | Supplied by macOS; this bundle does not redistribute those system binaries. No OpenBLAS or OpenMP dylib was observed. |

The inspected shipped-target compiler dependencies (common, llama, ggml, completion, cpp-httplib) contain no references to vendored hash helpers, stb, miniaudio, or base64.hpp. Their presence in the source checkout is not evidence of bundling. This negative build-record evidence does not exclude copied or unrecorded code. The subprocess component is sheredom; no component named “shredcomm” was identified.

The exact pinned upstream source files linked with the full notices below were compared byte-for-byte with the local checkout. Separate originating-project tags or commits for these vendored snapshots are not established. Retain Mozilla's MIT copyright and permission notice in distributions. Sheredom's public-domain dedication/Unlicense has no MIT-style attribution condition; its source credit and complete terms are included for provenance. No holder, year, or extra attribution obligation is invented.

## Notices required with downloadable MacPilot apps

The asset root and previously verified Xcode-built app contain `Qwen-model-provenance.txt`, `llama.cpp-LICENSE.txt`, and an earlier copy of `THIRD_PARTY_NOTICES.md` in `Contents/Resources/Licenses`. Those copies include the corrected Qwen attribution but lack the Mozilla llamafile and explicit sheredom notices added here. The build copies files from the supplied asset root's license directory; it does **not** automatically copy this root Markdown file into the app.

Before distributing an app, separately prepare the asset-root license directory so the built app carries:

1. The Qwen provenance and exact pinned publisher Apache 2.0 license, including `Copyright 2024 Alibaba Cloud`. No separate NOTICE exists in the checked GGUF revision.
2. The existing full llama.cpp/ggml MIT license and copyright notice.
3. Full nlohmann/json and cpp-httplib MIT notices (including the additional header copyright), the Mozilla llamafile MIT notice, and sheredom subprocess public-domain dedication/Unlicense. The base64 dedication is retained for reference without asserting runtime inclusion.
4. Any further notices established by the unresolved embedded-dependency audit.
5. This component inventory, or equivalent documentation that accompanies the download, with final runtime provenance and modification details.

A repository link or short attribution alone does not replace a required full license in the binary distribution. The full texts below consolidate the verified licenses in this source document; refreshing the stale asset-root copy, rebuilding and verifying the app, and completing runtime provenance and embedded-dependency checks require separate tasks. No asset or build-setting changes were made for this document.

## Full license texts

### Apache License 2.0 — Qwen

Source: [Pinned official Qwen LICENSE](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/blob/91cad51170dc346986eccefdc2dd33a9da36ead9/LICENSE). The appendix attribution is supplied by the publisher.

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright 2024 Alibaba Cloud

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### llama.cpp / ggml — MIT

```text
MIT License

Copyright (c) 2023-2026 The ggml authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### nlohmann/json — MIT

```text
MIT License

Copyright (c) 2013-2025 Niels Lohmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### cpp-httplib — MIT

```text
The MIT License (MIT)

Copyright (c) 2017 yhirose

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### base64.hpp — public-domain dedication / Unlicense

```text
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>
```

### llamafile embedded sgemm.cpp — MIT

Source: [Pinned upstream header](https://raw.githubusercontent.com/ggml-org/llama.cpp/5047748f114564fcf271e6a648f60e2d2eae6264/ggml/src/ggml-cpu/llamafile/sgemm.cpp). Only comment delimiters are removed.

```text
Copyright 2024 Mozilla Foundation

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### sheredom subprocess.h — public-domain dedication / Unlicense

Source: [Pinned vendored header](https://raw.githubusercontent.com/ggml-org/llama.cpp/5047748f114564fcf271e6a648f60e2d2eae6264/vendor/sheredom/subprocess.h), identifying [the originating project](https://github.com/sheredom/subprocess.h). Complete license comment, excluding delimiters:

```text
This is free and unencumbered software released into the public domain.

   Anyone is free to copy, modify, publish, use, compile, sell, or
   distribute this software, either in source code form or as a compiled
   binary, for any purpose, commercial or non-commercial, and by any
   means.

   In jurisdictions that recognize copyright laws, the author or authors
   of this software dedicate any and all copyright interest in the
   software to the public domain. We make this dedication for the benefit
   of the public at large and to the detriment of our heirs and
   successors. We intend this dedication to be an overt act of
   relinquishment in perpetuity of all present and future rights to this
   software under copyright law.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
   IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.

   For more information, please refer to <http://unlicense.org/>
```
