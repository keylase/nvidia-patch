#!/usr/bin/env python3

import sys
import subprocess
import tempfile
import os.path
from binascii import unhexlify
import xml.etree.ElementTree as ET


PATCH_EXT = ".1337"
CRLF = b"\x0d\x0a"
HEADER_FORMAT = b">%s"
LINE_FORMAT = CRLF + b"%016X:%02X->%02X"
OFFSET_ADJUSTMENT = 0xC00  # shift specific to x64dbg .1337 format


def parse_args():
    import argparse

    parser = argparse.ArgumentParser(
        description="Generates .1337 patch for Nvidia drivers for Windows",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("installer_file",
                        help="location of installer executable")
    parser.add_argument("-7", "--7zip",
                        default="7z",
                        dest="sevenzip",
                        help="location of 7-zip `7z` executable")
    parser.add_argument("-T", "--target",
                        default="Display.Driver/nvcuvid64.dl_",
                        help="target location in archive")
    parser.add_argument("-N", "--target-name",
                        default="nvcuvid.dll",
                        help="name of installed target file. Used for patch "
                        "header")
    parser.add_argument("-S", "--search",
                        default="FF908000000084C07408",
                        help="representation of search pattern binary string")
    parser.add_argument("-R", "--replacement",
                        default="FF908000000084C09090",
                        help="representation of replacement binary string")
    parser.add_argument("-o", "--stdout",
                        action="store_true",
                        help="output into stdout")
    args = parser.parse_args()
    return args


class ExtractException(Exception):
    pass


class PatternNotFoundException(Exception):
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
               sevenzip="7z"):
    with tempfile.TemporaryDirectory() as tmpdir:
        with ExtractedTarget(archive,
                             tmpdir,
                             arch_tgt,
                             sevenzip=sevenzip) as tgt:
            f = expand(tgt, sevenzip=sevenzip)
    offset = f.find(search)
    del f
    if offset == -1:
        raise PatternNotFoundException("Pattern not found.")
    print("Pattern found @ %016X" % (offset,), file=sys.stderr)

    res = []
    for (i, (left, right)) in enumerate(zip(search, replacement)):
        if left != right:
            res.append((offset + i, left, right))
    return res


def identify_driver(archive, *, sevenzip="7z"):
    manifest = extract_single_file(archive, "setup.cfg", sevenzip=sevenzip)
    root = ET.fromstring(manifest)
    version = root.attrib['version']
    product_type = root.find('./properties/string[@name="ProductType"]')\
        .attrib['value']
    return version, product_type


def format_patch(diff, filename):
    res = HEADER_FORMAT % filename.encode('utf-8')
    for offset, left, right in diff:
        res += LINE_FORMAT % (offset + OFFSET_ADJUSTMENT, left, right)
    return res


def main():
    args = parse_args()
    search = unhexlify(args.search)
    replacement = unhexlify(args.replacement)
    assert len(search) == len(replacement), "len() of search and replacement"\
        " is not equal"
    patch = make_patch(args.installer_file,
                       arch_tgt=args.target,
                       search=search,
                       replacement=replacement,
                       sevenzip=args.sevenzip)
    patch_content = format_patch(patch, args.target_name)
    if args.stdout:
        with open(sys.stdout.fileno(), mode='wb', closefd=False) as out:
            out.write(patch_content)
    else:
        version, product_type = identify_driver(args.installer_file,
                                                sevenzip=args.sevenzip)
        drv_prefix = {
            "100": "quadro_",
            "300": "",
            "301": "crd_",
        }
        driver_name = drv_prefix[product_type] + version
        out_dir = os.path.join(
            os.path.dirname(
                os.path.abspath(__file__)), '..', '..', 'win10_x64', driver_name)
        os.mkdir(out_dir, 0o755)
        out_filename = os.path.join(out_dir,
            os.path.splitext(args.target_name)[0] + PATCH_EXT)
        with open(out_filename, 'wb') as out:
            out.write(patch_content)


if __name__ == '__main__':
    main()
