#!/usr/bin/env python3

import urllib.request
import urllib.error
import urllib.parse
import codecs
import enum
import re
from bs4 import BeautifulSoup

USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64; rv:65.0) '\
             'Gecko/20100101 Firefox/65.0'


def parse_args():
    import argparse

    def check_positive_float(val):
        val = float(val)
        if val <= 0:
            raise ValueError("Value %s is not valid positive float" %
                             (repr(val),))
        return val

    parser = argparse.ArgumentParser(
        description="Retrieves info about latest NVIDIA drivers from "
        "downloads site",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-T", "--timeout",
                        type=check_positive_float,
                        default=10.,
                        help="timeout for network operations")
    args = parser.parse_args()
    return args


def issue_request(timeout=10):
    ENDPOINT = 'https://developer.nvidia.com/cuda-toolkit-archive'
    http_req = urllib.request.Request(
        ENDPOINT,
        data=None,
        headers={
            'User-Agent': USER_AGENT
        }
    )
    with urllib.request.urlopen(http_req, None, timeout) as resp:
        coding = resp.headers.get_content_charset()
        coding = coding if coding is not None else 'utf-8-sig'
        decoder = codecs.getreader(coding)(resp)
        res = decoder.read()
    return res


def get_latest_cuda_tk(*, timeout=10):
    doc = issue_request(timeout)
    soup = BeautifulSoup(doc, 'html.parser')

    res = soup.find('strong', string=re.compile(r'^\s*latest\s+release\s*$', re.I)).\
        parent.find('a', string=re.compile(r'^\s*cuda\s+toolkit\s+.*$', re.I)).\
        string
    return res


def main():
    import pprint
    args = parse_args()
    print(get_latest_cuda_tk(timeout=args.timeout))


if __name__ == '__main__':
    main()
