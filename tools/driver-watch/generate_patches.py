#!/usr/bin/env python3
"""Generate patches for the drivers listed by driver_watch.py, one commit each.

It mirrors the manual flow (.github/workflows/gen_linux_patches.yml and
gen_win_patches.yml) with extra safety checks, and never guesses a pattern:

* Linux: the NVENC and NvFBC patch strings are taken from patterns that
  patch.sh / patch-fbc.sh already use. A pattern is accepted only if it occurs
  exactly once in the new library. For NVENC the search used by
  tools/autopatch/find_bytecode.sh is the fallback. If nothing matches
  exactly once, the driver is reported as failed and nothing is committed.
* Windows: win/tools/autopatch/autopatch.py generates the .1337 files (it
  already requires exactly one match).

The working tree is modified and committed, so it must be disposable (a CI
checkout). Pass --allow-reset to confirm; a failed driver is rolled back with
`git reset --hard` and `git clean -fd`.

Writes a JSON report (--report) with one entry per driver and, with --pr-body,
the Markdown body for the pull request.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
AUTOPATCH_DIR = REPO / "tools" / "autopatch"
README_AUTOGEN = REPO / "tools" / "readme-autogen"
WIN_AUTOPATCH = REPO / "win" / "tools" / "autopatch" / "autopatch.py"

# tools/autopatch/find_bytecode.sh
NVENC_MATCH = "feff4189c685c0"
PATCH_LINE_RE = re.compile(r"""\["(?P<ver>[0-9][0-9.]*)"\]='s/(?P<search>.+?)/(?P<repl>.+?)/g'""")
HEX_ESCAPE_RE = re.compile(r"\\x([0-9a-fA-F]{2})")
USER_AGENT = "Mozilla/5.0 (compatible; nvidia-patch driver-watch)"
# On a Windows dev machine `bash` may be the WSL stub; set BASH_EXE to Git Bash there.
BASH = os.environ.get("BASH_EXE", "bash")


VERSION_RE = re.compile(r"^[0-9]+(\.[0-9]+)*$")
ALLOWED_HOSTS = {"download.nvidia.com", "international.download.nvidia.com", "us.download.nvidia.com"}


class GenerationFailed(Exception):
    """The driver cannot be patched automatically; the message says why."""


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def run(cmd, cwd=REPO, capture=False, env=None):
    result = subprocess.run(cmd, cwd=str(cwd), check=True, text=True, capture_output=capture, env=env)
    return result.stdout if capture else None


def git(*args, capture=False):
    return run(["git", *args], capture=capture)


def validate_candidate(candidate):
    """The candidate comes from a web API: only accept a plain version and an NVIDIA download host."""
    if candidate.get("platform") not in ("linux", "windows"):
        raise GenerationFailed("unknown platform")
    if not VERSION_RE.match(str(candidate.get("version", ""))):
        raise GenerationFailed("unexpected version string")
    check_nvidia_url(str(candidate.get("url", "")))


def check_nvidia_url(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in ALLOWED_HOSTS:
        raise GenerationFailed("download URL is not on an NVIDIA download host")


def download(url, dest):
    if dest.exists() and dest.stat().st_size > 0:
        log(f"using cached {dest.name}")
        return
    log(f"downloading {url}")
    tmp = dest.with_suffix(dest.suffix + ".part")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=120) as response:
        check_nvidia_url(response.geturl())  # urlopen follows redirects: check where it ended up
        with open(tmp, "wb") as out:
            shutil.copyfileobj(response, out, 1 << 20)
    tmp.replace(dest)


def commit(message, paths):
    git("add", "--", *paths)
    if not git("status", "--porcelain", "--", *paths, capture=True).strip():
        raise GenerationFailed("the tools changed nothing")
    git("commit", "-q", "-m", message)


def rollback():
    git("reset", "-q", "--hard", "HEAD")
    git("clean", "-fdq")


# ---------------------------------------------------------------- Linux


def bytes_of(escaped):
    return bytes(int(h, 16) for h in HEX_ESCAPE_RE.findall(escaped))


def patch_string(version, search, repl):
    def esc(data):
        return "".join(f"\\x{b:02x}" for b in data)

    return f"[\"{version}\"]='s/{esc(search)}/{esc(repl)}/g'"


def known_patterns(script):
    """Distinct (search, replacement) pairs used by patch.sh / patch-fbc.sh, newest first."""
    pairs = []
    for line in reversed((REPO / script).read_text(encoding="utf-8", errors="replace").splitlines()):
        match = PATCH_LINE_RE.search(line)
        if not match:
            continue
        pair = (bytes_of(match.group("search")), bytes_of(match.group("repl")))
        if len(pair[0]) == len(pair[1]) and pair[0] and pair not in pairs:
            pairs.append(pair)
    return pairs


def choose_pattern(lib, pairs, generic=None):
    """Return (search, replacement) that matches `lib` exactly once, or raise GenerationFailed."""
    matching = [pair for pair in pairs if lib.count(pair[0]) == 1]
    if len(matching) == 1:
        return matching[0]
    if len(matching) > 1:
        raise GenerationFailed(f"{len(matching)} different known patterns each match exactly once")
    if generic is not None:
        found = generic(lib)
        if found is not None:
            return found
    raise GenerationFailed("no known pattern matches exactly once")


def nvenc_generic(lib):
    """The find_bytecode.sh search: 3 bytes + feff4189c685c0, which must occur exactly once."""
    hexdump = lib.hex()
    hits = re.findall(".{0,6}" + NVENC_MATCH, hexdump)
    if len(hits) != 1:
        return None
    code = hits[0]
    fixed = code[:10] + "29c0" + code[-10:][:6]
    return bytes.fromhex(code), bytes.fromhex(fixed)


def extract_linux_libs(run_file, version, workdir):
    """Extract libnvidia-encode.so.V and libnvidia-fbc.so.V from the .run installer."""
    names = [f"libnvidia-encode.so.{version}", f"libnvidia-fbc.so.{version}"]
    if os.name == "nt":  # developer machine: 7-Zip opens the installer
        seven = shutil.which("7z") or shutil.which("7zz")
        if not seven:
            raise GenerationFailed("7z not found")
        run([seven, "x", "-y", f"-o{workdir}", str(run_file)], capture=True)
        tar = next(p for p in Path(workdir).iterdir() if p.is_file() and p.suffix != ".run")
        run([seven, "e", "-y", f"-o{workdir}/libs", str(tar), *names], capture=True)
        return Path(workdir) / "libs"
    os.chmod(run_file, 0o755)
    run([str(run_file), "-x"], cwd=workdir, capture=True)
    return Path(workdir) / f"NVIDIA-Linux-x86_64-{version}"


def insert_patch(script, line):
    """Add `line` to the patch_list of `script` with update_patch.sh and check that it landed verbatim.

    The string goes through the environment: quotes and backslashes in argv are mangled by
    some platforms (MSYS on Windows).
    """
    env = dict(os.environ, PATCH_STRING=line)
    run([BASH, "-c", 'exec ./update_patch.sh -f "$1" -b "$PATCH_STRING"', "bash", f"../../{script}"],
        cwd=AUTOPATCH_DIR, capture=True, env=env)
    if line not in (REPO / script).read_text(encoding="utf-8", errors="replace"):
        raise GenerationFailed(f"update_patch.sh did not insert the expected line into {script}")


def generate_linux(candidate, cache_dir):
    version = candidate["version"]
    # drivers.json uses the international mirror host
    url = candidate["url"].replace("//download.nvidia.com/", "//international.download.nvidia.com/")
    run_file = cache_dir / f"NVIDIA-Linux-x86_64-{version}.run"
    download(url, run_file)
    with tempfile.TemporaryDirectory() as workdir:
        libs = extract_linux_libs(run_file, version, workdir)
        enc_path, fbc_path = libs / f"libnvidia-encode.so.{version}", libs / f"libnvidia-fbc.so.{version}"
        if not enc_path.exists():
            raise GenerationFailed(f"{enc_path.name} not found in the installer")
        enc = choose_pattern(enc_path.read_bytes(), known_patterns("patch.sh"), nvenc_generic)
        fbc = None
        if fbc_path.exists():
            try:
                fbc = choose_pattern(fbc_path.read_bytes(), known_patterns("patch-fbc.sh"))
            except GenerationFailed as exc:
                log(f"linux {version}: NvFBC skipped ({exc})")

    paths = ["patch.sh", "drivers.json", "README.md"]
    insert_patch("patch.sh", patch_string(version, *enc))
    add = [sys.executable, "add_driver.py", "-L", "-U", url, version]
    if fbc is not None:
        insert_patch("patch-fbc.sh", patch_string(version, *fbc))
        paths.append("patch-fbc.sh")
    else:
        add.append("--no-fbc")
    run(add, cwd=README_AUTOGEN)
    run([sys.executable, "readme_autogen.py"], cwd=README_AUTOGEN)
    note = "" if fbc is not None else " (NVENC only)"
    commit(f"linux: add support for driver {version}{note}", paths)
    return "NVENC and NvFBC" if fbc is not None else "NVENC only, no NvFBC pattern matched"


# -------------------------------------------------------------- Windows


def generate_windows(candidate, cache_dir):
    version = candidate["version"]
    url = candidate["url"].replace("//us.download.nvidia.com/", "//international.download.nvidia.com/")
    installer = cache_dir / Path(url).name
    download(url, installer)

    started = time.time() - 2  # file timestamps can be coarser than the clock
    try:
        run([sys.executable, "-B", str(WIN_AUTOPATCH), str(installer)], cwd=WIN_AUTOPATCH.parent, capture=True)
    except subprocess.CalledProcessError as exc:
        # autopatch exits non-zero when it finds no usable pattern: that will repeat, it is not transient.
        last = (exc.stderr or "").strip().splitlines()[-1:] or ["no output"]
        raise GenerationFailed(f"autopatch failed (exit {exc.returncode}): {last[0][:150]}")

    # autopatch picks the directory itself (<version>, or nsd_<version> for a Studio installer
    # of the old product type), so use the one it just wrote instead of guessing from the API name.
    written = []
    for prefix in ("", "nsd_"):
        patch_dir = REPO / "win" / "win10_x64" / (prefix + version)
        files = [patch_dir / "nvencodeapi64.1337", patch_dir / "nvencodeapi.1337"]
        if all(f.exists() and f.stat().st_size > 0 and f.stat().st_mtime >= started for f in files):
            written.append((prefix, patch_dir))
    if len(written) != 1:
        raise GenerationFailed(f"autopatch wrote {len(written)} patch directories for {version}, expected 1")
    prefix, patch_dir = written[0]
    variant = "Studio Driver" if prefix == "nsd_" else "DCH"

    add = [sys.executable, "add_driver.py", "-W", "-P", "GeForce", "--variant", variant, "-w", "win10",
           "--skip-patch-check", "-U", url, version]
    run(add, cwd=README_AUTOGEN)
    run([sys.executable, "readme_autogen.py"], cwd=README_AUTOGEN)
    commit(f"win: add support for {variant} driver {version}", [str(patch_dir), "drivers.json", "win/README.md"])
    return variant


# ----------------------------------------------------------------- main


def pr_body(results, issues):
    lines = [
        "Generated automatically by the `Detect new drivers` workflow. "
        "**Nothing here has been tested on a GPU.** Each driver needs the 13-session test "
        "(`tools/patch-tester/patch-tester.sh` for Linux, `win/tools/patch-tester` for Windows) before merging.",
        "",
        "This branch is rebuilt from `master` on every run: do not push to it. Closing this pull request stops it "
        "from being reopened while the set of drivers below stays the same; close the issue of a driver to "
        "leave that driver out.",
        "",
    ]
    done = [r for r in results if r["status"] == "ok"]
    # Machine-readable list of the drivers in this pull request: the workflow does not recreate a
    # pull request that was closed unmerged for exactly this list.
    lines.append("<!-- drivers: " + ",".join(sorted(f"{r['platform']}:{r['version']}" for r in done)) + " -->")
    lines.append("")
    failed = [r for r in results if r["status"] in ("failed", "error", "undecided")]
    skipped = [r for r in results if r["status"] == "skipped"]
    if done:
        lines.append("## Generated")
        for r in done:
            number = issues.get(f"{r['platform']}:{r['version']}", {}).get("number")
            lines.append(f"- {r['platform']} {r['version']}: {r['message']}" + (f" (Fixes #{number})" if number else ""))
        lines.append("")
    if failed:
        lines.append("## Could not be generated automatically")
        lines.extend(f"- {r['platform']} {r['version']}: {r['message']}" for r in failed)
        lines.append("")
    if skipped:
        lines.append("## Skipped")
        lines.extend(f"- {r['platform']} {r['version']}: {r['message']}" for r in skipped)
        lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("candidates", help="JSON file written by driver_watch.py")
    parser.add_argument("--report", required=True, help="write the JSON report here")
    parser.add_argument("--pr-body", help="write the pull request body (Markdown) here")
    parser.add_argument("--issues", help="JSON file written by open_issues.py (issue number and state per driver)")
    parser.add_argument("--cache-dir", default=None, help="directory for downloaded installers")
    parser.add_argument("--allow-reset", action="store_true", help="confirm that the working tree is disposable")
    args = parser.parse_args()
    if not args.allow_reset:
        parser.error("--allow-reset is required: failed drivers are rolled back with git reset --hard / clean")

    candidates = json.loads(Path(args.candidates).read_text(encoding="utf-8"))
    issues = json.loads(Path(args.issues).read_text(encoding="utf-8")) if args.issues else {}
    cache_dir = Path(args.cache_dir or tempfile.mkdtemp(prefix="driver-watch-"))
    cache_dir.mkdir(parents=True, exist_ok=True)

    generators = {"linux": generate_linux, "windows": generate_windows}
    results = []
    for candidate in candidates:
        entry = {"platform": candidate["platform"], "version": candidate["version"]}
        issue = issues.get(f"{candidate['platform']}:{candidate['version']}", {})
        if issue.get("state") in ("CLOSED", "UNKNOWN"):
            unknown = issue["state"] == "UNKNOWN"
            why = "its issue could not be looked up" if unknown else f"its issue #{issue.get('number')} is closed"
            # An unknown state is not a decision: "undecided" counts as not done, "skipped" as done.
            entry.update(status="undecided" if unknown else "skipped", message=why)
            log(f"{entry['platform']} {entry['version']}: skipped - {why}")
            results.append(entry)
            continue
        try:
            validate_candidate(candidate)
            entry["message"] = generators[candidate["platform"]](candidate, cache_dir)
            entry["status"] = "ok"
        except GenerationFailed as exc:
            entry.update(status="failed", message=str(exc))
            rollback()
        except Exception as exc:  # one broken driver must not stop the others
            entry.update(status="error", message=f"{type(exc).__name__}: {exc}")
            rollback()
        log(f"{entry['platform']} {entry['version']}: {entry['status']} - {entry['message']}")
        results.append(entry)

    Path(args.report).write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    if args.pr_body:
        Path(args.pr_body).write_text(pr_body(results, issues), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
