#!/usr/bin/env python3

import sys
import argparse
import os.path
import itertools

PATCH_EXT = ".1337"
CRLF = b"\x0d\x0a"
HEADER_FORMAT = b">%s"
LINE_FORMAT = CRLF + b"%016X:%02X->%02X"
OFFSET_ADJUSTMENT = 0xC00


class ByteDiffException(Exception):
    """ Base class for all exceptions """
    pass


class LengthMismatchException(ByteDiffException):
    """ Throwed when length of input sequences do not match """
    pass


def check_positive_int(value):
    value = int(value)
    if value <= 0:
        raise argparse.ArgumentTypeError(
            "%s is an invalid positive number value" % value)
    return value


def parse_args():
    parser = argparse.ArgumentParser(
        description="Make .1337 patch file from original and patched files")
    parser.add_argument("orig_file",
                        metavar="ORIG_FILE",
                        help="original file")
    parser.add_argument("patched_file",
                        metavar="PATCHED_FILE",
                        help="patched file")
    parser.add_argument("output_file",
                        metavar="OUTPUT_FILE",
                        nargs='?',
                        help="filename for patch output. Default: basename of "
                        "original filename with .1337 extension")
    parser.add_argument("-f", "--header-filename",
                        metavar="FILENAME",
                        help="filename specified in resulting patch header. "
                        "Default: basename of original filename.")
    parser.add_argument("-l", "--limit",
                        help="stop after number of differences",
                        type=check_positive_int)
    args = parser.parse_args()
    return args


def feed_chunks(f, chunk_size=4096):
    """ Reads file-like object with chunks having up to `chunk_size` length """
    while True:
        buf = f.read(chunk_size)
        if not buf:
            break
        yield buf


def zip_files_bytes(*files):
    """ Iterate over two files, returning pair of bytes.
    Throw LengthMismatch if file sizes is uneven. """
    class EndMarker(object):
        pass
    end_marker = EndMarker()

    iterators = (itertools.chain.from_iterable(feed_chunks(f)) for f in files)
    for tup in itertools.zip_longest(*iterators, fillvalue=end_marker):
        if any(v is end_marker for v in tup):
            raise LengthMismatchException("Length of input files inequal.")
        yield tup


def diff(left, right):
    for offset, (a, b) in enumerate(zip_files_bytes(left, right)):
        if a != b:
            yield offset, a, b


def compose_diff_file(orig, patched, output, header, offset_adjustment=True):
    output.write(HEADER_FORMAT % (header.encode('latin-1'),))
    for offset, a, b in diff(orig, patched):
        o = offset + OFFSET_ADJUSTMENT if offset_adjustment else offset
        output.write(LINE_FORMAT % (o, a, b))


def main():
    args = parse_args()

    output_filename = args.output_file
    if not output_filename:
        orig_bname = os.path.basename(args.orig_file)
        before, _, after = orig_bname.rpartition('.')
        orig_bname_noext = before if before else after
        output_filename = orig_bname_noext + PATCH_EXT

    header_filename = args.header_filename
    if not header_filename:
        header_filename = os.path.basename(args.orig_file)

    with open(args.orig_file, 'rb') as orig,\
         open(args.patched_file, 'rb') as patched,\
         open(output_filename, 'wb') as output:
        try:
            compose_diff_file(orig, patched, output, header_filename)
        except LengthMismatchException:
            print("Input files have inequal length. Aborting...",
                  file=sys.stderr)


if __name__ == '__main__':
    main()
