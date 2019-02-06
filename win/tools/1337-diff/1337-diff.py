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


class DiffLimitException(ByteDiffException):
    """ Throwed when difference limit hit """
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


def zip_files_bytes(left, right):
    """ Iterate over two files, returning pair of bytes.
    Throw LengthMismatch if file sizes is uneven. """
    class EndMarker(object):
        pass
    end_marker = EndMarker()

    left_iter = itertools.chain.from_iterable(
        feed_chunks(left))
    right_iter = itertools.chain.from_iterable(
        feed_chunks(right))
    for a, b in itertools.zip_longest(left_iter,
                                      right_iter,
                                      fillvalue=end_marker):
        if a is end_marker or b is end_marker:
            raise LengthMismatchException("Length of input files inequal.")
        yield a, b


def diff(left, right, limit=None):
    offset = 0
    diff_count = 0
    for a, b in zip_files_bytes(left, right):
        if a != b:
            diff_count += 1
            if limit is not None and diff_count > limit:
                raise DiffLimitException()
            yield offset, a, b
        offset += 1


def compose_diff_file(orig, patched, output, header, *,
                      limit=None, offset_adjustment=True):
    output.write(HEADER_FORMAT % (header.encode('latin-1'),))
    adj = OFFSET_ADJUSTMENT if offset_adjustment else 0
    for offset, a, b in diff(orig, patched, limit):
        output.write(LINE_FORMAT % (offset + adj, a, b))


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
            compose_diff_file(orig, patched, output, header_filename,
                              limit=args.limit)
        except LengthMismatchException:
            print("Input files have inequal length. Aborting...",
                  file=sys.stderr)
        except DiffLimitException:
            print("Differences limit hit. Aborting...",
                  file=sys.stderr)


if __name__ == '__main__':
    main()
