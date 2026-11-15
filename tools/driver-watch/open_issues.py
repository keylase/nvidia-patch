#!/usr/bin/env python3
"""Open one GitHub issue per candidate printed by driver_watch.py.

Reads the candidate list (JSON) from the file given as argument, skips every
driver version that already appears in the title of any issue (open or closed,
by anyone) and creates the rest with the `gh` CLI. Needs GH_TOKEN and GH_REPO
(or a git remote) in the environment. With --dry-run nothing is created.
"""

import argparse
import json
import re
import subprocess
import sys

VERSION_RE = re.compile(r"^[0-9]+(\.[0-9]+)*$")


def gh(*args):
    result = subprocess.run(["gh", *args], check=True, capture_output=True, text=True)
    return result.stdout


def issue_exists(version):
    out = gh("issue", "list", "--state", "all", "--search", f'"{version}" in:title', "--json", "title")
    return any(version in issue["title"] for issue in json.loads(out))


def render(candidate):
    version, name, date, url = (candidate[k] for k in ("version", "name", "date", "url"))
    if candidate["platform"] == "linux":
        title = f"linux: new driver {version} needs a patch"
        how = (
            f"Run the **Generate Linux patches** workflow with version `{version}` and mode `search`, "
            "then test with `tools/patch-tester/patch-tester.sh` (13 concurrent sessions)."
        )
    else:
        variant = "Studio Driver" if "Studio" in name else "DCH"
        title = f"win: new driver {version} needs a patch"
        how = (
            f"Run the **Generate Windows patches** workflow with version `{version}` and variant `{variant}`, "
            "then test with `win/tools/patch-tester` (13 concurrent sessions)."
        )
    body = (
        f"NVIDIA released **{name} {version}** on {date}. There is no patch for it in this repository yet.\n\n"
        f"Download: {url}\n\n{how}\n"
    )
    return title, body


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("candidates", help="JSON file written by driver_watch.py")
    parser.add_argument("--dry-run", action="store_true", help="print what would be opened")
    args = parser.parse_args()

    with open(args.candidates, encoding="utf-8") as handle:
        candidates = json.load(handle)
    print(f"{len(candidates)} candidate(s)")

    for candidate in candidates:
        version = candidate["version"]
        if not VERSION_RE.match(version):
            print("skipping an unexpected version string")
            continue
        if issue_exists(version):
            print(f"{candidate['platform']} {version}: an issue already exists, skipping")
            continue
        title, body = render(candidate)
        if args.dry_run:
            print(f"DRY RUN, would open: {title}")
            continue
        gh("issue", "create", "--title", title, "--body", body, "--label", "enhancement")
        print(f"opened: {title}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
