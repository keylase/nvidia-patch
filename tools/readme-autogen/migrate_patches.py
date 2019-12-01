#!/usr/bin/env python3

import sys
import argparse
import json
import os.path
import posixpath
from string import Template
from itertools import groupby
from functools import partial
import urllib.request
import urllib.parse

from constants import OSKind, Product, WinSeries, DATAFILE_PATH, \
    DRIVER_URL_TEMPLATE, DRIVER_DIR_PREFIX, BASE_PATH, REPO_BASE
from utils import find_driver, linux_driver_key, windows_driver_key

def posixpath_components(path):
    result = []
    while True:
        head, tail = posixpath.split(path)
        if head == path:
            break
        result.append(tail)
        path = head
    result.reverse()
    if result and not result[-1]:
        result.pop()
    return result

def validate_patch(patch64, patch32):
    wc_base = os.path.abspath(os.path.join(BASE_PATH, "..", ".."))
    base_parse = urllib.parse.urlsplit(REPO_BASE, scheme='http')
    p64_parse = urllib.parse.urlsplit(patch64, scheme='http')
    p32_parse = urllib.parse.urlsplit(patch32, scheme='http')
    if not (p64_parse[0] == p32_parse[0] == base_parse[0]):
        raise Exception("URL scheme doesn't match repo base URL scheme")
    if not (p64_parse[1] == p32_parse[1] == base_parse[1]):
        raise Exception("URL network location doesn't match repo base URL network location")
    if posixpath.commonpath((base_parse[2], p64_parse[2], p32_parse[2])) != \
        posixpath.commonpath((base_parse[2],)):
        raise Exception("URL is not subpath of repo base path")
    p64_posix_relpath = posixpath.relpath(p64_parse[2], base_parse[2])
    p32_posix_relpath = posixpath.relpath(p32_parse[2], base_parse[2])
    p64_comp = posixpath_components(p64_posix_relpath)
    p32_comp = posixpath_components(p32_posix_relpath)
    p64_filepath = os.path.join(wc_base, *p64_comp)
    p32_filepath = os.path.join(wc_base, *p32_comp)
    if not os.path.exists(p64_filepath):
        raise Exception("File %s not found!" % p64_filepath)
    if not os.path.exists(p32_filepath):
        raise Exception("File %s not found!" % p32_filepath)
    if os.path.getsize(p64_filepath) == 0:
        raise Exception("File %s empty!" % p64_filepath)
    if os.path.exists(p32_filepath) == 0:
        raise Exception("File %s empty!" % p32_filepath)

def main():
    with open(DATAFILE_PATH) as data_file:
        data = json.load(data_file)

    drivers = data[OSKind.Linux.value]['x86_64']['drivers']
    for d in drivers:
        d['nvenc_patch'] = True
        d['nvfbc_patch'] = False
        if 'driver_url' in d:
            driver_url = d['driver_url']
            del d['driver_url']
            d['driver_url'] = driver_url
    with open(DATAFILE_PATH, 'w') as data_file:
        json.dump(data, data_file, indent=4)

if __name__ == '__main__':
    main()
