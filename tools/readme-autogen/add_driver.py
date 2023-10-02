#!/usr/bin/env python3

import sys
import argparse
import json
import os.path
import posixpath
from string import Template
from functools import partial
import urllib.request

from constants import OSKind, Product, WinSeries, DATAFILE_PATH, \
    DRIVER_URL_TEMPLATE, DRIVER_DIR_PREFIX, BASE_PATH
from utils import find_driver, linux_driver_key, windows_driver_key

def parse_args():
    def check_enum_arg(enum, value):
        try:
            return enum[value]
        except KeyError:
            raise argparse.ArgumentTypeError("%s is not valid option for %s" % (repr(value), repr(enum.__name__)))

    parser = argparse.ArgumentParser(
        description="Adds new Nvidia driver into drivers.json file of "
        "in your repo working copy",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    os_options = parser.add_argument_group("OS options")
    os_group=os_options.add_mutually_exclusive_group(required=True)
    os_group.add_argument("-L", "--linux",
                          action="store_const",
                          dest="os",
                          const=OSKind.Linux,
                          help="add Linux driver")
    os_group.add_argument("-W", "--win",
                          action="store_const",
                          dest="os",
                          const=OSKind.Windows,
                          help="add Windows driver")
    win_opts = parser.add_argument_group("Windows-specific options")
    win_opts.add_argument("--variant",
                          default="",
                          help="driver variant (use for special cases like "
                          "\"Studio Driver\")")
    win_opts.add_argument("-P", "--product",
                          type=partial(check_enum_arg, Product),
                          choices=list(Product),
                          default=Product.GeForce,
                          help="product type")
    win_opts.add_argument("-w", "--winseries",
                          type=partial(check_enum_arg, WinSeries),
                          choices=list(WinSeries),
                          default=WinSeries.win10,
                          help="Windows series")
    win_opts.add_argument("--patch32",
                          default="${winseries}_x64/"
                          "${drvprefix}${version}/nvencodeapi.1337",
                          help="template for Windows 32bit patch URL")
    win_opts.add_argument("--patch64",
                          default="${winseries}_x64/"
                          "${drvprefix}${version}/nvencodeapi64.1337",
                          help="template for Windows 64bit patch URL")
    win_opts.add_argument("--skip-patch-check",
                          action="store_true",
                          help="skip patch files presense test")
    parser.add_argument("-U", "--url",
                        help="override driver link")
    parser.add_argument("--skip-url-check",
                        action="store_true",
                        help="skip driver URL check")
    parser.add_argument("--no-fbc",
                        dest="fbc",
                        action="store_false",
                        help="add driver w/o NvFBC patch")
    parser.add_argument("--no-enc",
                        dest="enc",
                        action="store_false",
                        help="add driver w/o NVENC patch")
    parser.add_argument("version",
                        help="driver version")
    args = parser.parse_args()
    return args

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

def validate_url(url):
    req = urllib.request.Request(url, method="HEAD")
    with urllib.request.urlopen(req, timeout=10) as resp:
        if int(resp.headers['Content-Length']) < 50 * 2**20:
            raise Exception("Bad driver length: %s" % resp.headers['Content-Length'])

def validate_patch(patch64, patch32):
    wc_base = os.path.abspath(os.path.join(BASE_PATH, "..", "..", "win"))
    p64_filepath = os.path.join(wc_base, patch64)
    p32_filepath = os.path.join(wc_base, patch32)
    if not os.path.exists(p64_filepath):
        raise Exception("File %s not found!" % p64_filepath)
    if not os.path.exists(p32_filepath):
        raise Exception("File %s not found!" % p32_filepath)
    if os.path.getsize(p64_filepath) == 0:
        raise Exception("File %s empty!" % p64_filepath)
    if os.path.exists(p32_filepath) == 0:
        raise Exception("File %s empty!" % p32_filepath)

def validate_unique(drivers, new_driver, kf):
    if find_driver(drivers, kf(new_driver), kf) is not None:
        raise Exception("Duplicate driver!")

def main():
    args = parse_args()
    if not args.url:
        if args.os is OSKind.Linux:
            url_tmpl = DRIVER_URL_TEMPLATE[(args.os, None, None, None)]
        else:
            url_tmpl = DRIVER_URL_TEMPLATE[(args.os,
                                            args.product,
                                            args.winseries,
                                            args.variant)]
        if isinstance(url_tmpl, str):
            url_tmpl = [url_tmpl]
        urls = [Template(i).substitute(version=args.version) for i in url_tmpl if i]
    else:
        urls = [args.url]
    url = ""
    if urls and not args.skip_url_check:
        last_exc = None
        for url in urls:
            try:
                validate_url(url)
                break
            except KeyboardInterrupt:
                raise
            except Exception as exc:
                last_exc = exc
        else:
            print("Driver URL validation failed with error: %s" % str(last_exc), file=sys.stderr)
            print("Driver URL: %s" % ", ".join(urls), file=sys.stderr)
            print("Please use option -U to override driver link manually", file=sys.stderr)
            print("or use option --skip-url-check to submit incorrect URL.", file=sys.stderr)
            return

    if args.os is OSKind.Windows:
        driver_dir_prefix = DRIVER_DIR_PREFIX[(args.product, args.variant)]
        patch64_url = Template(args.patch64).substitute(winseries=args.winseries,
                                                        drvprefix=driver_dir_prefix,
                                                        version=args.version)
        patch32_url = Template(args.patch32).substitute(winseries=args.winseries,
                                                        drvprefix=driver_dir_prefix,
                                                        version=args.version)
        if not args.skip_patch_check:
            try:
                validate_patch(patch64_url, patch32_url)
            except KeyboardInterrupt:
                raise
            except Exception as exc:
                print("Driver patch validation failed with error: %s" % str(exc), file=sys.stderr)
                print("Use options --patch64 and --patch32 to override patch path ", file=sys.stderr)
                print("template or use option --skip-patch-check to submit driver with ", file=sys.stderr)
                print("missing patch files.", file=sys.stderr)
                return
    with open(DATAFILE_PATH) as data_file:
        data = json.load(data_file)

    drivers = data[args.os.value]['x86_64']['drivers']
    if args.os is OSKind.Windows:
        new_driver = {
            "os": str(args.winseries),
            "product": str(args.product),
            "version": args.version,
            "variant": args.variant,
            "patch64_url": patch64_url,
            "patch32_url": patch32_url,
            "driver_url": url,
        }
        key_fun = windows_driver_key
    else:
        new_driver = {
            "version": args.version,
            "nvenc_patch": args.enc,
            "nvfbc_patch": args.fbc,
        }
        if url:
            new_driver["driver_url"] = url
        key_fun = linux_driver_key
    drivers = sorted(drivers, key=key_fun)
    try:
        validate_unique(drivers, new_driver, key_fun)
    except KeyboardInterrupt:
        raise
    except Exception as exc:
        print("Driver uniqueness validation failed with error: %s" % str(exc), file=sys.stderr)
        return
    data[args.os.value]['x86_64']['drivers'].append(new_driver)
    with open(DATAFILE_PATH, 'w') as data_file:
        json.dump(data, data_file, indent=4)
        data_file.write('\n')

if __name__ == '__main__':
    main()
