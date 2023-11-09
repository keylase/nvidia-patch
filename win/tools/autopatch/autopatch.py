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
                        default=[
                            "8BF085C0750549892FEB",
                            "89450885C08B450C75048938EB",
                        ],
                        help="representation of search pattern(s) binary string")
    parser.add_argument("-R", "--replacement",
                        nargs="+",
                        default=[
                            "33C08BF0750549892FEB",
                            "33C08945088B450C75048938EB",
                        ],
                        help="representation of replacement(s) binary string")
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

class ExtractedTarget:
    name = None

    def __init__(self, archive, dst_dir, arch_tgt, *, sevenzip="7z"):
        self._archive = archive
        self._dst_dir = dst_dir
        self._sevenzip = sevenzip
        self._arch_tgt = arch_tgt

    def __enter__(self):
        ret = subprocess.call([self._sevenzip,
                               "e",
                               "-o" + self._dst_dir,
                               self._archive,
                               self._arch_tgt],
                              stdout=sys.stderr)
        if ret != 0:
            raise ExtractException("Subprocess returned non-zero exit code.")
        name = os.path.join(self._dst_dir, os.path.basename(self._arch_tgt))
        self.name = name
        return name

    def __exit__(self, exc_type, exc_value, traceback):
        if self.name is not None:
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

    if args.direct:
        combinations = zip(args.installer_file, args.search, args.replacement,
                           args.target, args.target_name, args.patch_name)
    else:
        base_params = zip(args.search, args.replacement, args.target, args.target_name, args.patch_name)
        combinations = ((l,) + r for l, r in itertools.product(args.installer_file, base_params))

    with tempfile.TemporaryDirectory() as tempdir:
        print(f"Using tempdir `{tempdir}`")
        for params in combinations:
            patch_flow(*params, tempdir=tempdir, direct=args.direct, stdout=args.stdout)


if __name__ == '__main__':
    main()
