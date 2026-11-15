#!/usr/bin/env python3
"""List recent NVIDIA drivers that this repository has no patch for yet.

Linux:   versions from NVIDIA's official directory index that are in neither
         patch.sh nor patch-fbc.sh and were uploaded within --max-age-days.
Windows: versions returned by NVIDIA's driver lookup API that are not in
         drivers.json and were released within --max-age-days.

Prints a JSON list of candidates (see Candidate) to stdout. Progress and errors
go to stderr. Exit code 1 only if every source failed. Uses the standard
library only.
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
    unpatched = sorted(
        (v for v in versions if v not in patched and version_key(v)[0] >= LINUX_MIN_MAJOR),
        key=version_key,
    )
    log(f"linux: {len(versions)} versions in the index, {len(unpatched)} unpatched with major >= {LINUX_MIN_MAJOR}")

    found = []
    for version in unpatched:
        url = LINUX_RUN.format(v=version)
        try:
            headers, _ = http_retry(url, method="HEAD")
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            log(f"linux: {version}: HEAD failed ({exc}); skipped")
            continue
        modified = headers.get("Last-Modified")
        if not modified:
            continue
        uploaded = email.utils.parsedate_to_datetime(modified)
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
    return found


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
    failures = 0
    queries = list(windows_queries())
    for url in queries:
        try:
            _, body = http_retry(url)
            result = json.loads(body.decode("utf-8", "replace"))
        except (urllib.error.URLError, TimeoutError, OSError, ValueError) as exc:
            failures += 1
            log(f"windows: query failed ({exc})")
            continue
        for entry in result.get("IDS", []):
            info = entry.get("downloadInfo", {})
            version = info.get("Version")
            if not version or version in known or version in seen:
                continue
            released = urllib.parse.unquote(info.get("ReleaseDateTime", ""))
            try:
                date = datetime.datetime.strptime(released, "%a %b %d, %Y").replace(tzinfo=datetime.timezone.utc)
            except ValueError:
                date = None
            if date is not None and age_days(date, now) > max_age_days:
                continue
            seen[version] = {
                "platform": "windows",
                "version": version,
                "name": urllib.parse.unquote(info.get("Name", "")),
                "date": date.date().isoformat() if date else released,
                "url": urllib.parse.unquote(info.get("DownloadURL", "")),
            }
    log(f"windows: {len(queries) - failures}/{len(queries)} queries ok, {len(seen)} new versions")
    if failures == len(queries):
        raise RuntimeError("all Windows queries failed")
    return sorted(seen.values(), key=lambda c: version_key(c["version"]))


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
            candidates.extend(source(args.max_age_days, now))
        except (urllib.error.URLError, TimeoutError, OSError, RuntimeError) as exc:
            errors += 1
            log(f"{name}: failed ({exc})")

    json.dump(candidates, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 1 if errors == len(sources) else 0


if __name__ == "__main__":
    sys.exit(main())
