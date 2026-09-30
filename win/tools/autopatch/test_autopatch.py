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
from unittest import mock

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


@unittest.skipUnless(shutil.which(SEVENZIP), "7z is not installed")
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
            search=[SEARCH],
            replacement=[REPLACEMENT],
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
                search=[SEARCH],
                replacement=[REPLACEMENT],
                tmpdir=self._tmp,
                sevenzip=SEVENZIP,
            )


# ---------------------------------------------------------------------------
# Bytecode generation auto-detection, explicit -S/-R alternatives and argument
# validation. These use direct (-D) mode so they need no 7z and no installer.
# ---------------------------------------------------------------------------

NEUTRAL = b"\x90" * 8  # padding that matches none of the known patterns

PRIMARY_S = "8BF04533FF85C0"
PRIMARY_R = "33C08BF04533FF"
FALLBACK_S = "8BF085C0750549892FEB"
FALLBACK_R = "33C08BF0750549892FEB"


def _hex(value):
    return bytes.fromhex(value)


def _expected_diff(offset, search, replacement):
    return [(offset + i, a, b) for i, (a, b) in enumerate(zip(search, replacement)) if a != b]


class BytecodeAutoDetectTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self._tmp, ignore_errors=True)

    def _direct(self, data, search, replacement):
        path = os.path.join(self._tmp, "lib.bin")
        with open(path, "wb") as fo:
            fo.write(data)
        return autopatch.make_patch(
            path,
            arch_tgt="unused.dll",
            search=search,
            replacement=replacement,
            tmpdir=self._tmp,
            direct=True,
        )

    def test_auto_detect_picks_each_generation(self):
        # Each table entry, alone in the binary, must be selected and must
        # produce exactly the same diff as passing that pattern explicitly.
        for search_hex, replacement_hex in autopatch.BYTECODE_GENERATIONS:
            with self.subTest(generation=search_hex):
                search = _hex(search_hex)
                replacement = _hex(replacement_hex)
                data = NEUTRAL + search + NEUTRAL
                self.assertEqual(autopatch.select_bytecode(data), (search, replacement))
                auto = self._direct(data, None, None)
                explicit = self._direct(data, [search], [replacement])
                self.assertEqual(auto, explicit)
                self.assertEqual(auto, _expected_diff(len(NEUTRAL), search, replacement))

    def test_auto_detect_fails_when_no_generation_matches(self):
        self.assertIsNone(autopatch.select_bytecode(NEUTRAL))
        with self.assertRaises(autopatch.PatternNotFoundException):
            self._direct(NEUTRAL, None, None)

    def test_explicit_comma_alternatives_use_the_one_present(self):
        search = autopatch.parse_binary_alternatives(PRIMARY_S + "," + FALLBACK_S)
        replacement = autopatch.parse_binary_alternatives(PRIMARY_R + "," + FALLBACK_R)
        data = NEUTRAL + _hex(FALLBACK_S) + NEUTRAL
        self.assertEqual(
            self._direct(data, search, replacement),
            _expected_diff(len(NEUTRAL), _hex(FALLBACK_S), _hex(FALLBACK_R)),
        )

    def test_explicit_first_listed_alternative_wins(self):
        # Both alternatives occur once; the first one *in list order* is used,
        # regardless of where it sits in the binary.
        data = _hex(FALLBACK_S) + NEUTRAL + _hex(PRIMARY_S)
        primary = (_hex(PRIMARY_S), _hex(PRIMARY_R))
        fallback = (_hex(FALLBACK_S), _hex(FALLBACK_R))

        diff = self._direct(data, [primary[0], fallback[0]], [primary[1], fallback[1]])
        self.assertEqual(diff, _expected_diff(len(FALLBACK_S) // 2 + len(NEUTRAL), *primary))

        diff = self._direct(data, [fallback[0], primary[0]], [fallback[1], primary[1]])
        self.assertEqual(diff, _expected_diff(0, *fallback))

    def test_duplicate_fallback_does_not_break_unique_primary(self):
        # Regression for #1074: a fallback that occurs twice must not cause a
        # failure when the primary occurs exactly once.
        search = [_hex(PRIMARY_S), _hex(FALLBACK_S)]
        replacement = [_hex(PRIMARY_R), _hex(FALLBACK_R)]
        data = _hex(PRIMARY_S) + NEUTRAL + _hex(FALLBACK_S) + NEUTRAL + _hex(FALLBACK_S)
        self.assertEqual(
            self._direct(data, search, replacement),
            _expected_diff(0, _hex(PRIMARY_S), _hex(PRIMARY_R)),
        )

    def test_duplicate_selected_pattern_is_rejected(self):
        data = _hex(PRIMARY_S) + NEUTRAL + _hex(PRIMARY_S)
        with self.assertRaises(autopatch.MultipleOccurencesException):
            self._direct(data, [_hex(PRIMARY_S)], [_hex(PRIMARY_R)])


class ArgumentValidationTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self._tmp, ignore_errors=True)

    def test_empty_alternative_is_rejected(self):
        for value in ["", "8BF0,", ",8BF0", "8BF0,,33C0"]:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    autopatch.parse_binary_alternatives(value)

    def test_defaults_are_none_when_omitted(self):
        with mock.patch.object(sys, "argv", ["autopatch.py", "installer.exe"]):
            args = autopatch.parse_args()
        self.assertIsNone(args.search)
        self.assertIsNone(args.replacement)

    def test_search_without_replacement_is_rejected(self):
        argv = ["autopatch.py", "installer.exe", "-S", PRIMARY_S]
        with mock.patch.object(sys, "argv", argv):
            with self.assertRaises(ValueError):
                autopatch.main()

    def test_replacement_without_search_is_rejected(self):
        argv = ["autopatch.py", "installer.exe", "-R", PRIMARY_R]
        with mock.patch.object(sys, "argv", argv):
            with self.assertRaises(ValueError):
                autopatch.main()

    def test_patch_flow_rejects_search_without_replacement(self):
        with self.assertRaises(ValueError):
            autopatch.patch_flow("installer.exe", PRIMARY_S, None, "t.dll", "t.dll",
                                 "t.1337", tempdir=self._tmp, direct=True)


if __name__ == "__main__":
    unittest.main()
