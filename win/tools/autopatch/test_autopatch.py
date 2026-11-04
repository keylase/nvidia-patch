#!/usr/bin/env python3

"""Regression tests for autopatch.py target extraction.

The NVENC libraries in Nvidia installer archives are stored under different
names depending on the driver generation:

  * older drivers (e.g. 496.13): ``Display.Driver/nvencodeapi64.dl_``
    (LZMA-compressed, extension ``.dl_``)
  * newer drivers:               ``Display.Driver/nvencodeapi64.dll``
    (stored raw, extension ``.dll``)

autopatch.py defaults to the ``.dll`` spelling, so it must fall back to the
``.dl_`` spelling when the archive only contains the compressed variant.
Before the fix, a missing target silently produced nothing (7z exits 0 with
"No files to process"), and the subsequent ``open()``/``os.remove()`` raised a
confusing ``FileNotFoundError`` that masked the real problem.

These tests build a throw-away archive with 7z so they do not depend on a
multi-hundred-megabyte driver download.
"""

import io
import lzma
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import autopatch  # noqa: E402  (path is prepared above)

SEVENZIP = os.environ.get("SEVENZIP", "7z")

SEARCH = b"\x8b\xf0\x45\x33\xff\x85\xc0"
REPLACEMENT = b"\x33\xc0\x8b\xf0\x45\x33\xff"


def _payload():
    # Unique context around the pattern so `find` is unambiguous.
    return b"NVENC-HEADER" + SEARCH + b"NVENC-TAIL" + b"\x00" * 16


def _make_archive(tmpdir, member, data, *, compress):
    """Create a 7z archive containing ``member`` (forward-slash path)."""
    tree = os.path.join(tmpdir, "tree")
    abs_member = os.path.join(tree, *member.split("/"))
    os.makedirs(os.path.dirname(abs_member), exist_ok=True)
    with open(abs_member, "wb") as fo:
        fo.write(lzma.compress(data) if compress else data)

    archive = os.path.join(tmpdir, "archive.7z")
    root = os.path.join(tree, member.split("/")[0])
    subprocess.check_call(
        [SEVENZIP, "a", "-t7z", archive, root],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return archive


class MakePatchTargetResolutionTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self._tmp, ignore_errors=True)

    def _run(self, member, *, compress):
        archive = _make_archive(self._tmp, member, _payload(),
                                compress=compress)
        # mirror the default --target spelling (.dll)
        return autopatch.make_patch(
            archive,
            arch_tgt="Display.Driver/nvencodeapi64.dll",
            search=SEARCH,
            replacement=REPLACEMENT,
            tmpdir=self._tmp,
            sevenzip=SEVENZIP,
        )

    def test_raw_dll_target_is_found(self):
        diff = self._run("Display.Driver/nvencodeapi64.dll", compress=False)
        self.assertTrue(diff, "expected a non-empty diff for a raw .dll member")

    def test_compressed_dl_target_is_found(self):
        # 496.13-style archive: only the compressed .dl_ member exists.
        diff = self._run("Display.Driver/nvencodeapi64.dl_", compress=True)
        self.assertTrue(
            diff,
            "expected autopatch to fall back to the .dl_ member and find the "
            "pattern",
        )

    def test_missing_target_raises_extract_exception(self):
        # Neither spelling is present: must raise a clear error, not a bare
        # FileNotFoundError from open()/os.remove().
        archive = _make_archive(self._tmp, "Display.Driver/somethingelse.dll",
                                _payload(), compress=False)
        with self.assertRaises(autopatch.ExtractException):
            autopatch.make_patch(
                archive,
                arch_tgt="Display.Driver/nvencodeapi64.dll",
                search=SEARCH,
                replacement=REPLACEMENT,
                tmpdir=self._tmp,
                sevenzip=SEVENZIP,
            )


if __name__ == "__main__":
    unittest.main()
