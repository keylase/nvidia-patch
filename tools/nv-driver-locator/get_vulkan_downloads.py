#!/usr/bin/env python3

import sys
import urllib.request
import urllib.error
import urllib.parse
import codecs
import enum
import re
from bs4 import BeautifulSoup

USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64; rv:65.0) '\
             'Gecko/20100101 Firefox/65.0'
URL = 'https://developer.nvidia.com/vulkan-driver'

def parse_args():
    import argparse

    def check_positive_float(val):
        val = float(val)
        if val <= 0:
            raise ValueError("Value %s is not valid positive float" %
                             (repr(val),))
        return val

    parser = argparse.ArgumentParser(
        description="Retrieves info about latest NVIDIA Vulkan beta drivers "
                    "from developer downloads site",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-T", "--timeout",
                        type=check_positive_float,
                        default=10.,
                        help="timeout for network operations")
    args = parser.parse_args()
    return args


def fetch_url(url, timeout=10):
    http_req = urllib.request.Request(
        url,
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


def get_drivers(*, timeout=10):
    body = fetch_url(URL)
    soup = BeautifulSoup(body, 'html.parser')
    result = []
    for sibling in soup.find('h4',
                             string=re.compile(r'Vulkan .* Developer Beta Driver Downloads', re.I)
                             ).next_siblings:
        if sibling.name == 'h4':
            break
        if sibling.name == 'p' and sibling.b is not None:
            m = re.match(r'(Windows|Linux)\s+((\d+\.){1,2}\d+)', sibling.b.string)
            if m is not None:
                ver = m.group(2)
                os = m.group(1)
                obj = {
                    "name": "Vulkan Beta Driver for %s" % (os,),
                    "os": os,
                    "version": ver,
                }
                result.append(obj)
    return result


def main():
    import pprint
    args = parse_args()
    pprint.pprint(get_drivers(timeout=args.timeout))


if __name__ == '__main__':
    main()
