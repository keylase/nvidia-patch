#!/usr/bin/env python3

import argparse
import functools
import itertools
import os.path
import subprocess
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
from binascii import unhexlify

CRLF = b"\x0d\x0a"
HEADER_FORMAT = b">%s"
LINE_FORMAT = CRLF + b"%016X:%02X->%02X"
OFFSET_ADJUSTMENT = 0xC00  # shift specific to x64dbg .1337 format


# NVENC libraries ship exactly one of a handful of bytecode generations,
# depending on the driver family. Historically the newest generation was
# hardcoded as the default and bumped by hand whenever a new driver changed the
# code, which silently broke every older driver. Listing the known generations
# here (newest first) and auto-selecting the one that matches lets a single
# build of this tool handle every driver without editing the defaults.
# Each entry is a (search, replacement) pair of equal-length hex strings; both
# the 64-bit and 32-bit libraries follow the same table because their patterns
# are disjoint. Values are taken from this file's own history.
BYTECODE_GENERATIONS = (
    # 591.xx and newer
    ("8BF04533FF85C0", "33C08BF04533FF"),
    ("8985ECFBFFFF85C08B85DCFBFFFF7504",
     "31C08985ECFBFFFF8B85DCFBFFFF7504"),
    # ~2022-06 variant (x64)
    ("8BF085C0750549892FEB", "33C08BF0750549892FEB"),
    # ~2022-02 era (x64)
    ("8BE885C0750548893EEB", "33C08BE8750548893EEB"),
    # ~2022 era (x86)
    ("89450885C08B450C75048938EB", "33C08945088B450C75048938EB"),
    # ~2019-11 (x86)
    ("89450885C075048937EB", "33C089450875048937EB"),
    # ~2019-10
    ("FF909800000084C075", "FF90980000000C0175"),
    ("8B404CFFD084C075", "8B404CFFD00C0175"),
)


def select_bytecode(data):
    """Return the ``(search, replacement)`` pair matching ``data`` exactly once.

    Returns ``None`` when no known generation matches unambiguously, so the
    caller can report a clear error instead of guessing.
    """
    for search_hex, replacement_hex in BYTECODE_GENERATIONS:
        search = unhexlify(search_hex)
        if data.count(search) == 1:
            return search, unhexlify(replacement_hex)
    return None


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generates .1337 patch for Nvidia drivers for Windows",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("installer_file",
                        nargs="+",
                        help="location of installer executable(s)")
    parser.add_argument("-7", "--7zip",
                        default="7z",
                        dest="sevenzip",
                        help="location of 7-zip `7z` executable")
    parser.add_argument("-T", "--target",
                        nargs="+",
                        default=[
                            "Display.Driver/nvencodeapi64.dll",
                            "Display.Driver/nvencodeapi.dll",
                        ],
                        help="target location(s) in archive")
    parser.add_argument("-N", "--target-name",
                        nargs="+",
                        default=[
                            "nvencodeapi64.dll",
                            "nvencodeapi.dll",
                        ],
                        help="name(s) of installed target file. Used for patch "
                             "header")
    parser.add_argument("-P", "--patch-name",
                        nargs="+",
                        default=[
                            "nvencodeapi64.1337",
                            "nvencodeapi.1337",
                        ],
                        help="relative filename(s) of generated patch(es)")
    parser.add_argument("-S", "--search",
                        nargs="+",
                        default=None,
                        help="representation of search pattern(s) binary "
                             "string (default: auto-detect from the target "
                             "library)")
    parser.add_argument("-R", "--replacement",
                        nargs="+",
                        default=None,
                        help="representation of replacement(s) binary string "
                             "(default: auto-detect from the target library)")
    parser.add_argument("-o", "--stdout",
                        action="store_true",
                        help="output into stdout")
    parser.add_argument("-D", "--direct",
                        action="store_true",
                        help="supply patched library directly instead of "
                             "installer file")
    args = parser.parse_args()
    return args


class ExtractException(Exception):
    pass


class PatternNotFoundException(Exception):
    pass


class MultipleOccurencesException(Exception):
    pass


class UnknownPlatformException(Exception):
    pass

class InstallerNotFoundException(Exception):
    pass


def _alternate_target_names(arch_tgt):
    """Return ``arch_tgt`` plus its ``.dll``/``.dl_`` spelling variant.

    NVENC libraries are stored either raw (``nvencodeapi64.dll``) or
    LZMA-compressed (``nvencodeapi64.dl_``) depending on the driver
    generation, and the caller may request either spelling. Both are tried so
    that a target present under the other name is still picked up.
    """
    names = [arch_tgt]
    basename = os.path.basename(arch_tgt)
    if basename.endswith(".dll"):
        alternate = basename[:-len(".dll")] + ".dl_"
    elif basename.endswith(".dl_"):
        alternate = basename[:-len(".dl_")] + ".dll"
    else:
        alternate = None
    if alternate is not None:
        names.append(os.path.join(os.path.dirname(arch_tgt), alternate))
    return names


class ExtractedTarget:
    name = None

    def __init__(self, archive, dst_dir, arch_tgt, *, sevenzip="7z"):
        self._archive = archive
        self._dst_dir = dst_dir
        self._sevenzip = sevenzip
        self._arch_tgt = arch_tgt

    def __enter__(self):
        # 7z exits 0 with "No files to process" when the requested member is
        # absent, so a successful return code is not enough: verify a file
        # actually appeared and fall back to the .dll/.dl_ spelling variant.
        for arch_tgt in _alternate_target_names(self._arch_tgt):
            ret = subprocess.call([self._sevenzip,
                                   "e",
                                   "-o" + self._dst_dir,
                                   self._archive,
                                   arch_tgt],
                                  stdout=sys.stderr)
            if ret != 0:
                raise ExtractException(
                    "Subprocess returned non-zero exit code.")
            name = os.path.join(self._dst_dir, os.path.basename(arch_tgt))
            if os.path.isfile(name):
                self.name = name
                return name
        raise ExtractException(
            "Target %r not found in archive %r (also tried the .dll/.dl_ "
            "variant)." % (self._arch_tgt, self._archive))

    def __exit__(self, exc_type, exc_value, traceback):
        if self.name is not None and os.path.isfile(self.name):
            os.remove(self.name)


def expand(filename, *, sevenzip="7z"):
    proc = subprocess.Popen([sevenzip,
                             "x",
                             "-so",
                             filename], stdout=subprocess.PIPE)
    result = proc.communicate()[0]
    if proc.returncode != 0:
        raise ExtractException("Subprocess returned non-zero exit code.")
    return result


def extract_single_file(archive, filename, *, sevenzip="7z"):
    proc = subprocess.Popen([sevenzip,
                             "e",
                             "-so",
                             archive,
                             filename], stdout=subprocess.PIPE)
    result = proc.communicate()[0]
    if proc.returncode != 0:
        raise ExtractException("Subprocess returned non-zero exit code.")
    return result


def make_patch(archive, *,
               arch_tgt,
               search,
               replacement,
               tmpdir,
               sevenzip="7z",
               direct=False):
    if direct:
        with open(archive, 'rb') as fo:
            f = fo.read()
    else:
        with ExtractedTarget(archive,
                             tmpdir,
                             arch_tgt,
                             sevenzip=sevenzip) as tgt:
            if tgt.endswith(".dll"):
                with open(tgt, 'rb') as fo:
                    f = fo.read()
            else:
                f = expand(tgt, sevenzip=sevenzip)
    if search is None or replacement is None:
        selected = select_bytecode(f)
        if selected is None:
            raise PatternNotFoundException(
                "No known NVENC bytecode generation matched exactly once in "
                "%r; pass -S/-R explicitly." % (arch_tgt,))
        search, replacement = selected
    offset = f.find(search)
    if offset == -1:
        raise PatternNotFoundException("Pattern not found.")
    if f[offset + len(search):].find(search) != -1:
        raise MultipleOccurencesException("Multiple occurences of pattern found!")
    del f
    print("Pattern found @ %016X" % (offset,), file=sys.stderr)

    res = []
    for (i, (left, right)) in enumerate(zip(search, replacement)):
        if left != right:
            res.append((offset + i, left, right))
    return res


@functools.lru_cache(maxsize=None)
def identify_driver(archive, *, sevenzip="7z"):
    manifest = extract_single_file(archive, "setup.cfg", sevenzip=sevenzip)
    root = ET.fromstring(manifest)
    version = root.attrib['version']
    product_type = root.find('./properties/string[@name="ProductType"]') \
        .attrib['value']
    return version, product_type


def format_patch(diff, filename):
    res = HEADER_FORMAT % filename.encode('utf-8')
    for offset, left, right in diff:
        res += LINE_FORMAT % (offset + OFFSET_ADJUSTMENT, left, right)
    return res


def patch_flow(installer_file, search, replacement, target, target_name, patch_name, *,
               tempdir, direct=False, stdout=False, sevenzip="7z"):
    if (search is None) != (replacement is None):
        raise ValueError(
            "Both -S/--search and -R/--replacement must be given together, "
            "or neither (to auto-detect).")
    if search is not None:
        search = unhexlify(search)
        replacement = unhexlify(replacement)
        assert len(search) == len(replacement), "len() of search and replacement is not equal"

    # Check if installer file exists or try to download

    print(f"Search for installer file `{installer_file}`...")
    if not os.path.isfile(installer_file):
        print("Installer file is not a file...")
        if not installer_file.startswith("http"):
            print("Installer file is not a URL...")

            # Construct URL from version
            print("Installer file is a version!")
            filename = installer_file + "-desktop-win10-win11-64bit-international-dch-whql.exe"
            installer_url = f"https://international.download.nvidia.com/Windows/{installer_file}/{filename}"
        else:
            print("Installer file is a URL!")
            installer_url = installer_file

        if installer_url:
            try:
                file_path = os.path.join(tempdir, os.path.basename(installer_url))
                if not os.path.isfile(file_path):
                    with urllib.request.urlopen(installer_url) as response, open(file_path, 'wb') as out_file:
                        print(f"Downloading... ({installer_url} TO {file_path})")
                        print("This may take a while (~800MB)")
                        out_file.write(response.read())
                        print("Download completed successfully!")
                        installer_file = file_path
                else:
                    print(f"Using downloaded file in '{file_path}'")
                    installer_file = file_path
            except (urllib.error.URLError, Exception) as e:
                raise InstallerNotFoundException(f"Failed to download the file: {e}")
            except Exception as e:
                raise InstallerNotFoundException(f"An error occurred during download: {str(e)}")
        else:
            raise InstallerNotFoundException(f"Invalid installer file or version: {installer_file}")

    # Rest of the code remains the same...
    patch = make_patch(installer_file,
                       arch_tgt=target,
                       search=search,
                       replacement=replacement,
                       tmpdir=tempdir,
                       sevenzip=sevenzip,
                       direct=direct)
    patch_content = format_patch(patch, target_name)

    if stdout:
        sys.stdout.buffer.write(patch_content)
    elif direct:
        with open(patch_name, mode='wb') as out:
            out.write(patch_content)
    else:
        version, product_type = identify_driver(installer_file, sevenzip=sevenzip)
        drv_prefix = {
            "100": "quadro_",
            "103": "quadro_",
            "300": "",
            "301": "nsd_",
            "303": "",  # DCH
            "304": "nsd_",
        }
        installer_name = os.path.basename(installer_file).lower()
        if 'winserv2008' in installer_name or 'winserv-2012' in installer_name:
            os_prefix = 'ws2012_x64'
        elif 'winserv-2016' in installer_name or 'win10' in installer_name:
            os_prefix = 'win10_x64'
        elif 'win7' in installer_name:
            os_prefix = 'win7_x64'
        else:
            raise UnknownPlatformException(f"Can't infer platform from filename {installer_name}")

        driver_name = drv_prefix.get(product_type, "") + version
        out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', os_prefix, driver_name)
        os.makedirs(out_dir, 0o755, exist_ok=True)
        out_filename = os.path.join(out_dir, patch_name)
        with open(out_filename, 'wb') as out:
            out.write(patch_content)


def main():
    args = parse_args()

    if args.search is None:
        # No explicit patterns: auto-detect per target library.
        count = len(args.installer_file) if args.direct else len(args.target)
        search = [None] * count
        replacement = [None] * count
    else:
        if args.replacement is None:
            raise ValueError(
                "Both -S/--search and -R/--replacement must be given together, "
                "or neither (to auto-detect).")
        search = args.search
        replacement = args.replacement

    if args.direct:
        combinations = zip(args.installer_file, search, replacement,
                           args.target, args.target_name, args.patch_name)
    else:
        base_params = zip(search, replacement, args.target, args.target_name, args.patch_name)
        combinations = ((l,) + r for l, r in itertools.product(args.installer_file, base_params))

    with tempfile.TemporaryDirectory() as tempdir:
        print(f"Using tempdir `{tempdir}`")
        for params in combinations:
            patch_flow(*params, tempdir=tempdir, direct=args.direct, stdout=args.stdout)


if __name__ == '__main__':
    main()
