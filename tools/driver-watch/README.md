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

The exit code is 1 only if every source failed.

`open_issues.py` takes that list and opens one issue per driver with the `gh` CLI. It skips versions that already appear in the title of any issue, open or closed, so it can run repeatedly:

```bash
python3 tools/driver-watch/driver_watch.py > candidates.json
python3 tools/driver-watch/open_issues.py candidates.json --dry-run
```
