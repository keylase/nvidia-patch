#!/usr/bin/env python3
"""List recent NVIDIA drivers that this repository has no patch for yet.

Linux:   versions from NVIDIA's official directory index that are in neither
         patch.sh nor patch-fbc.sh and were uploaded within --max-age-days.
Windows: versions returned by NVIDIA's driver lookup API that are not in
         drivers.json and were released within --max-age-days.

Prints a JSON list of candidates to stdout (always, even on failure). Progress
and errors go to stderr. Exit code 1 if any source failed or could only be
read partially, so a blind spot does not look like "nothing new". Uses the
standard library only.
"""

import argparse
import datetime
import email.utils
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
USER_AGENT = "Mozilla/5.0 (compatible; nvidia-patch driver-watch)"
TIMEOUT = 60

LINUX_INDEX = "https://download.nvidia.com/XFree86/Linux-x86_64/"
LINUX_RUN = LINUX_INDEX + "{v}/NVIDIA-Linux-x86_64-{v}.run"
# Older drivers are not interesting: this repository does not add new ones.
LINUX_MIN_MAJOR = 500

WIN_API = (
    "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/"
    "AjaxDriverService.php?func=DriverManualLookup"
)
# (psid, pfid): GeForce RTX 3080 and a second GeForce desktop product.
WIN_PRODUCTS = ((120, 929), (131, 1076))
WIN_OS_IDS = (57, 135)  # Windows 10 64-bit, Windows 11
WIN_RESULTS = 10  # the API times out with large values

VERSION_KEY_RE = re.compile(r'\["(\d[\d.]*)"\]=')
INDEX_VERSION_RE = re.compile(r"href='(\d+\.\d+(?:\.\d+)?)/'")
VERSION_RE = re.compile(r"^\d+(\.\d+)*$")


def log(msg):
    print(msg, file=sys.stderr)


def version_key(version):
    return tuple(int(part) for part in version.split("."))


def http(url, method="GET"):
    request = urllib.request.Request(url, method=method, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return response.headers, response.read()


def http_retry(url, method="GET", attempts=2):
    last = None
    for _ in range(attempts):
        try:
            return http(url, method)
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            last = exc
    raise last


def age_days(moment, now):
    return (now - moment).total_seconds() / 86400


def linux_candidates(max_age_days, now):
    patched = set()
    for name in ("patch.sh", "patch-fbc.sh"):
        text = (REPO / name).read_text(encoding="utf-8", errors="replace")
        patched.update(VERSION_KEY_RE.findall(text))

    _, body = http_retry(LINUX_INDEX)
    versions = set(INDEX_VERSION_RE.findall(body.decode("utf-8", "replace")))
    if not versions:
        # A real index lists hundreds of versions: an empty answer is a broken page, not "nothing new".
        raise RuntimeError("the Linux index contains no driver versions")
    unpatched = sorted(
        (v for v in versions if v not in patched and version_key(v)[0] >= LINUX_MIN_MAJOR),
        key=version_key,
    )
    log(f"linux: {len(versions)} versions in the index, {len(unpatched)} unpatched with major >= {LINUX_MIN_MAJOR}")

    found, problems = [], 0
    for version in unpatched:
        url = LINUX_RUN.format(v=version)
        try:
            headers, _ = http_retry(url, method="HEAD")
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            log(f"linux: {version}: HEAD failed ({exc}); skipped")
            # The index lists a few directories without a .run file (404): not a problem.
            if not (isinstance(exc, urllib.error.HTTPError) and exc.code == 404):
                problems += 1
            continue
        modified = headers.get("Last-Modified")
        try:
            uploaded = email.utils.parsedate_to_datetime(modified)
        except (TypeError, ValueError):
            log(f"linux: {version}: unusable Last-Modified {modified!r}; skipped")
            problems += 1
            continue
        if uploaded.tzinfo is None:
            uploaded = uploaded.replace(tzinfo=datetime.timezone.utc)
        if age_days(uploaded, now) > max_age_days:
            continue
        found.append(
            {
                "platform": "linux",
                "version": version,
                "name": "NVIDIA Linux x86_64 driver",
                "date": uploaded.date().isoformat(),
                "url": url,
            }
        )
    return found, problems


def known_windows_versions():
    data = json.loads((REPO / "drivers.json").read_text(encoding="utf-8"))
    known = set()

    def walk(node):
        if isinstance(node, dict):
            url = node.get("driver_url", "")
            if "version" in node and "/Windows/" in url:
                known.add(str(node["version"]))
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(data)
    return known


# Game Ready (upCRD=0) is queried before Studio (upCRD=1) and the first hit per version wins. NVIDIA
# usually ships the same version number for both, and this repository only maintains the DCH patches
# for recent drivers (the Studio patch of the same version is identical), so one candidate per version
# is intended. A version that exists only as Studio is still found; generate_patches.py then uses the
# directory and variant that autopatch actually produced.
def windows_queries():
    for psid, pfid in WIN_PRODUCTS:
        for os_id in WIN_OS_IDS:
            for studio in (0, 1):
                yield (
                    f"{WIN_API}&psid={psid}&pfid={pfid}&osID={os_id}&languageCode=1033"
                    f"&beta=0&isWHQL=0&dltype=-1&dch=1&upCRD={studio}&qnf=0&sort1=0"
                    f"&numberOfResults={WIN_RESULTS}"
                )


def windows_candidates(max_age_days, now):
    known = known_windows_versions()
    seen = {}
    problems = 0
    queries = list(windows_queries())
    for url in queries:
        try:
            _, body = http_retry(url)
            result = json.loads(body.decode("utf-8", "replace"))
        except (urllib.error.URLError, TimeoutError, OSError, ValueError) as exc:
            problems += 1
            log(f"windows: query failed ({exc})")
            continue
        if not isinstance(result, dict) or not isinstance(result.get("IDS"), list):
            # Success responses carry an "IDS" list; an error body must not read as "no new driver".
            problems += 1
            log(f"windows: unexpected response ({str(result)[:100]})")
            continue
        for entry in result["IDS"]:
            info = entry.get("downloadInfo", {})
            version = info.get("Version")
            if not version:
                # A real entry always has a version; "DriverDownloadIDNotFound" and the like do not.
                problems += 1
                log(f"windows: entry without a version ({str(info)[:100]})")
                continue
            if version in known or version in seen:
                continue
            if not VERSION_RE.match(version):
                log(f"windows: unexpected version string {version!r}; skipped")
                problems += 1
                continue
            released = urllib.parse.unquote(info.get("ReleaseDateTime", ""))
            try:
                date = datetime.datetime.strptime(released, "%a %b %d, %Y").replace(tzinfo=datetime.timezone.utc)
            except ValueError:
                # Fail closed: without a date the age window cannot be applied.
                log(f"windows: {version}: unparseable ReleaseDateTime {released!r}; skipped")
                problems += 1
                continue
            if age_days(date, now) > max_age_days:
                continue
            seen[version] = {
                "platform": "windows",
                "version": version,
                "name": urllib.parse.unquote(info.get("Name", "")),
                "date": date.date().isoformat(),
                "url": urllib.parse.unquote(info.get("DownloadURL", "")),
            }
    log(f"windows: {len(queries) - problems}/{len(queries)} queries ok, {len(seen)} new versions")
    return sorted(seen.values(), key=lambda c: version_key(c["version"])), problems


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--max-age-days", type=float, default=21, help="ignore drivers older than this (default: 21)")
    parser.add_argument("--only", choices=("linux", "windows"), help="check one platform only")
    args = parser.parse_args()

    now = datetime.datetime.now(datetime.timezone.utc)
    sources = {"linux": linux_candidates, "windows": windows_candidates}
    if args.only:
        sources = {args.only: sources[args.only]}

    candidates, errors = [], 0
    for name, source in sources.items():
        try:
            found, problems = source(args.max_age_days, now)
        except Exception as exc:  # keep the other platform running whatever went wrong here
            errors += 1
            log(f"{name}: failed ({type(exc).__name__}: {exc})")
            continue
        candidates.extend(found)
        if problems:
            errors += 1
            log(f"{name}: {problems} problem(s), the result may be incomplete")

    json.dump(candidates, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
