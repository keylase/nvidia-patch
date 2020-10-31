#!/usr/bin/env python3

import urllib.request
import urllib.error
import json
import posixpath
import codecs
import gzip
import sys
from contextlib import contextmanager
import itertools
import string
import codecs
import pprint
import re
import collections

USER_AGENT = 'Debian APT-HTTP/1.3 (1.6.6)'
DEFAULT_REPO = "https://developer.download.nvidia.com/"\
    "compute/cuda/repos/ubuntu1804/x86_64/Packages.gz"
DEFAULT_REGEX = '^cuda-drivers$'
ENCODING = 'utf-8-sig'

DriverEntry = collections.namedtuple('DriverEntry', ('name', 'version'))

def upstream_version(version):
	epoch, delim, tail = version.partition(':')
	version = tail if delim else epoch
	return version.partition('-')[0]

@contextmanager
def packages_reader(url, timeout):
    http_req = urllib.request.Request(
        url,
        data=None,
        headers={
            'User-Agent': USER_AGENT
        }
    )
    with urllib.request.urlopen(http_req, None, timeout) as resp:
        if url.endswith('.gz') or resp.headers.get('Content-Type', '') == 'application/x-gzip':
            with gzip.GzipFile(fileobj=resp) as reader:
                yield codecs.getreader(ENCODING)(reader)
        else:
            yield codecs.getreader(ENCODING)(resp)

def parse_packages(reader):
    for k, g in itertools.groupby(reader, lambda s: bool(s.strip())):
        if not k:
            continue
        pkg = dict()
        current_key = None
        current_val = None
        for line in g:
            if line[0] in string.whitespace:
                # Continuation
                if current_key is None:
                    continue
                current_val += line.rstrip()
            else:
                # New field
                if current_key is not None:
                    pkg[current_key.lower()] = current_val
                current_key, _, current_val = line.partition(':')
                current_val = current_val.strip()
        if current_key is not None:
            pkg[current_key.lower()] = current_val
        if 'package' in pkg and 'version' in pkg:
            yield pkg

def _get_deb_versions(*, url=DEFAULT_REPO, name=DEFAULT_REGEX, timeout=10):
    pattern = re.compile(name)
    with packages_reader(url, timeout) as lines:
        for pkg in parse_packages(lines):
            if pattern.match(pkg['package']) is not None:
                yield DriverEntry(pkg['package'], upstream_version(pkg['version']))

def get_deb_versions(*args, **kwargs):
	return list(set(_get_deb_versions(*args, **kwargs)))


def parse_args():
    import argparse

    def check_positive_float(val):
        val = float(val)
        if val <= 0:
            raise ValueError("Value %s is not valid positive float" %
                             (repr(val),))
        return val

    parser = argparse.ArgumentParser(
        description="Retrieves info about latest NVIDIA drivers available in "
        "Nvidia deb packages repositories",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-U", "--url",
                        default=DEFAULT_REPO,
                        help="URL for Packages or Packages.gz file")
    parser.add_argument("-N", "--name",
                        default=DEFAULT_REGEX,
                        help="Package name regexp")
    parser.add_argument("-T", "--timeout",
                        type=check_positive_float,
                        default=10.,
                        help="timeout for network operations")
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    drv = get_deb_versions(url=args.url,
                           name=args.name,
                           timeout=args.timeout)
    if drv is None:
        print("NOT FOUND")
        sys.exit(3)
    if False: #not args.raw:
        print("Version: %s" % (drv['DriverAttributes']['Version'],))
        print("Beta: %s" % (bool(int(drv['DriverAttributes']['IsBeta'])),))
        print("WHQL: %s" % (bool(int(drv['DriverAttributes']['IsWHQL'])),))
        print("URL: %s" % (drv['DriverAttributes']['DownloadURLAdmin'],))
    else:
        json.dump(drv, sys.stdout, indent=4)
        sys.stdout.flush()


if __name__ == '__main__':
    main()
