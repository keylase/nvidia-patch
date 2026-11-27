driver-watch
============

`driver_watch.py` lists recent NVIDIA drivers that this repository has no patch for yet. It is used by the `Detect new drivers` workflow, which opens one issue per driver.

* **Linux**: versions in NVIDIA's [directory index](https://download.nvidia.com/XFree86/Linux-x86_64/) that are in neither `patch.sh` nor `patch-fbc.sh`. The upload time of the `.run` file (`Last-Modified`) is used as release date.
* **Windows**: versions returned by NVIDIA's driver lookup API (GeForce desktop, Windows 10/11, DCH, Game Ready and Studio) that are not in `drivers.json`.

Drivers older than `--max-age-days` (default 21) are ignored, so old gaps do not produce issues.

## Requirements

* Python 3.8+, standard library only.

## Usage

```bash
python3 tools/driver-watch/driver_watch.py                    # JSON list of candidates on stdout
python3 tools/driver-watch/driver_watch.py --only linux --max-age-days 60
```

The exit code is 1 if any source failed or could only be read partially, so a blind spot does not look like "nothing new". The JSON list is printed in either case.

`open_issues.py` takes that list and opens one issue per driver with the `gh` CLI. It skips a driver that already has an issue (see *Operating notes*), so it can run repeatedly:

```bash
python3 tools/driver-watch/driver_watch.py > candidates.json
python3 tools/driver-watch/open_issues.py candidates.json --dry-run
```

## Patch generation

`generate_patches.py` creates the patches for the candidates and commits them, one commit per driver. It never guesses:

* **Linux**: the NVENC and NvFBC patterns come from patterns that `patch.sh` / `patch-fbc.sh` already use, and are accepted only if they occur exactly once in the new `libnvidia-encode` / `libnvidia-fbc`. For NVENC the search of `tools/autopatch/find_bytecode.sh` is the fallback. If nothing matches exactly once, the driver is reported as failed. If only NvFBC fails, the driver is added with `--no-fbc`.
* **Windows**: `win/tools/autopatch` (it requires exactly one match).

The working tree must be disposable, hence `--allow-reset`: a failed driver is rolled back with `git reset --hard` and `git clean -fd`. On a Windows developer machine set `BASH_EXE` to Git Bash, because `bash` may be the WSL stub.

The `Detect new drivers` workflow pushes the result to the branch `bot/new-drivers` (rebuilt from `master` each run) and keeps one draft pull request for it. This needs *Allow GitHub Actions to create and approve pull requests* in the repository settings. Nothing is merged automatically and no patch is tested on a GPU.

## Operating notes

* **Issues**: a driver counts as having an issue if one exists (open or closed) with the exact title this tool creates (`linux: new driver X needs a patch`, `win: new driver X needs a patch`), or one made from the repository's request template (`New driver support (version X)`). A request only means "already covered": no second issue is opened, but it is never linked with `Fixes #N` and its state does not matter, because it carries no platform. A free-form report that merely mentions the version does not count. **Close the bot's own issue to leave that driver out for good.**
* If the issue lookup fails, the driver is skipped for that run (it is never assumed to have no issue), and the bot pull request is left untouched in that run, so it is not rebuilt without that driver.
* **Closing the pull request is a decision**: it is not recreated while the set of generated drivers stays the same (the pull request body carries a hidden `<!-- drivers: ... -->` list). A new driver changes the set and opens a new pull request.
* When a run generates nothing and no driver failed (everything merged, aged out, or left out by a closed issue), the open bot pull request is closed with a comment. If a driver only failed to generate, or if a source could not be read completely, the pull request is left alone. The reasons are in the run summary.
* A driver that cannot be patched for a lasting reason (no pattern matches exactly once, or the installer is gone: HTTP 404/410) is reported under *Could not be generated*, and the other drivers are still handled. A transient problem (a download or tool error, or an unknown issue state) makes the run leave the bot pull request untouched, so it is neither rebuilt without that driver nor reopened for a smaller set.
* Known limit: when a run generates nothing but some other driver failed or is undecided, the open pull request is left alone, so a driver you just left out by closing its issue stays in it until the next clean run (no commit can express a removal). Do not merge such a pull request before checking its list of drivers.
* A driver is a candidate for 21 days after its release.
* The branch `bot/new-drivers` is force-pushed on every run that produces commits. Do not push to it.
* Installers are cached per set of candidates (`actions/cache`), so a pending driver is not downloaded again every 3 hours.
* Game Ready and Studio drivers often share a version number; one candidate per version is created (Game Ready preferred).
