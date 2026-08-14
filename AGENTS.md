# AGENTS.md

This repo provides NVENC/NvFBC patches for Nvidia drivers on Linux (`patch.sh`, `patch-fbc.sh`)
and Windows (`.1337` files under `win/`, applied via Win_1337_Apply_Patch).

## Golden rules

- **Never hand-edit generated artifacts.** `README.md`, `win/README.md`, and `drivers.json`
  are generated. `drivers.json` is the single source of truth; the READMEs are rebuilt from it
  and the `tools/readme-autogen/templates/` templates.
- **Never hand-edit the `patch_list` in `patch.sh`/`patch-fbc.sh`.** Use the autopatch scripts.
- The canonical end-to-end flow is `.github/workflows/gen_linux_patches.yml` and
  `.github/workflows/gen_win_patches.yml` — mirror them when working manually.

## Testing: >12 simultaneous NVENC sessions

The unpatched driver fails past 12 concurrent sessions; the patch must allow 13+.

- **Linux**: `tools/patch-tester/patch-tester.sh` — runs 13 concurrent `h264_nvenc` encodes
  (1M–13M bitrate) against `testsrc` via CUDA. All 13 must complete without error.
  Requires ffmpeg built with NVENC/CUDA support and the patched driver installed.
- **Windows**: `win/tools/patch-tester/patch-tester.ps1` (or `.bat`) — same 13-stream test.

Test against the patched driver and confirm 13 sessions succeed on a consumer GPU before opening a PR.
