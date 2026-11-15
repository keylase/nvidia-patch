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

`open_issues.py` takes that list and opens one issue per driver with the `gh` CLI. It skips a driver that already has an issue, open or closed: one with the exact title this tool creates for that platform and version (`linux: new driver X needs a patch`, `win: new driver X needs a patch`), or one made from the repository's request template (`New driver support (version X)`). A user report that merely mentions the version does not count. So it can run repeatedly:

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

* **Closing the pull request is a decision**: it is not recreated while the set of generated drivers stays the same (the pull request body carries a hidden `<!-- drivers: ... -->` list). A new driver changes the set and opens a new pull request. To leave a driver out for good, close its issue (the report then lists it as skipped).
* When a run produces no commit (everything merged, aged out, skipped because its issue is closed, or not generable), the open bot pull request is closed with a comment, so it never keeps drivers that no longer belong in it. The reasons are in the run summary.
* A driver is a candidate for 21 days after its release.
* The branch `bot/new-drivers` is force-pushed on every run that produces commits. Do not push to it.
* Installers are cached per set of candidates (`actions/cache`), so a pending driver is not downloaded again every 3 hours.
* Game Ready and Studio drivers often share a version number; one candidate per version is created (Game Ready preferred).
