#!/usr/bin/env python3

import urllib.request
import urllib.error
import json
import posixpath
import codecs

USER_AGENT = 'NvBackend/36.0.0.0'


def serialize_req(obj):
    return json.dumps(obj, separators=(',', ':'))


def getDispDrvrByDevid(query_obj, timeout=10):
    ENDPOINT = 'https://gfwsl.geforce.com/nvidia_web_services/' \
        'controller.gfeclientcontent.NG.php/' \
        'com.nvidia.services.GFEClientContent_NG.getDispDrvrByDevid'
    url = posixpath.join(ENDPOINT, serialize_req(query_obj))
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
        res = json.load(decoder)
    return res


def get_latest_geforce_driver(*,
                              notebook=False,
                              x86_64=True,
                              os_version="10.0",
                              os_build="17763",
                              language=1033,
                              beta=False,
                              dch=False,
                              crd=False,
                              timeout=10):
    # GeForce GTX 1080 and GP104 HD Audio
    dt_id = ["1B80_10DE_119E_10DE"]
    # GeForce GTX 1080 Mobile
    nb_id = ["1BE0_10DE"]

    dev_id = nb_id if notebook else dt_id
    query_obj = {
        "dIDa": dev_id,                   # Device PCI IDs:
                                          # ["DEVID_VENID_DEVID_VENID"]
        "osC": os_version,                # OS version (Windows 10)
        "osB": os_build,                  # OS build
        "is6": "1" if x86_64 else "0",    # 0 - 32bit, 1 - 64bit
        "lg": str(language),              # Language code
        "iLp": "1" if notebook else "0",  # System Is Laptop
        "prvMd": "0",                     # Private Model?
        "gcV": "3.18.0.94",               # GeForce Experience client version
        "gIsB": "1" if beta else "0",     # Beta?
        "dch": "1" if dch else "0",       # 0 - Standard Driver, 1 - DCH Driver
        "upCRD": "1" if crd else "0",     # Searched driver: 0 - GameReady Driver, 1 - CreatorReady Driver
        "isCRD": "1" if crd else "0",     # Installed driver: 0 - GameReady Driver, 1 - CreatorReady Driver
    }
    try:
        res = getDispDrvrByDevid(query_obj, timeout)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            res = None
        else:
            raise e
    return res


def parse_args():
    import argparse

    def parse_lang(lang):
        lang = int(lang)
        if not (0x0 <= lang <= 0xFFFF):
            raise ValueError("Bad language ID")
        return lang

    def check_positive_float(val):
        val = float(val)
        if val <= 0:
            raise ValueError("Value %s is not valid positive float" %
                             (repr(val),))
        return val

    parser = argparse.ArgumentParser(
        description="Retrieves info about latest NVIDIA drivers from GeForce "
        "Experience",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-V", "--os-version",
                        default="10.0",
                        help="OS version")
    parser.add_argument("-B", "--os-build",
                        default="17763",
                        help="OS build")
    parser.add_argument("-l", "--language",
                        default=1033,
                        type=parse_lang,
                        help="Driver language code")
    parser.add_argument("-m", "--notebook",
                        help="Query for notebook drivers (Mobile series)",
                        action="store_true")
    parser.add_argument("-3", "--32bit",
                        help="Query for 32bit drivers",
                        dest="_32bit",
                        action="store_true")
    parser.add_argument("-b", "--beta",
                        help="Allow beta-versions in search result",
                        action="store_true")
    parser.add_argument("-D", "--dch",
                        help="Query DCH driver instead of Standard driver",
                        action="store_true")
    parser.add_argument("-C", "--crd",
                        help="Query CreatorReady driver instead of "
                        "GameReady driver",
                        action="store_true")
    parser.add_argument("-T", "--timeout",
                        type=check_positive_float,
                        default=10.,
                        help="timeout for network operations")
    parser.add_argument("-R", "--raw",
                        help="Raw JSON output",
                        action="store_true")
    args = parser.parse_args()
    return args


def main():
    import sys
    args = parse_args()
    drv = get_latest_geforce_driver(os_version=args.os_version,
                                    os_build=args.os_build,
                                    language=args.language,
                                    notebook=args.notebook,
                                    x86_64=(not args._32bit),
                                    beta=args.beta,
                                    dch=args.dch,
                                    crd=args.crd,
                                    timeout=args.timeout)
    if drv is None:
        print("NOT FOUND")
        sys.exit(3)
    if not args.raw:
        print("Version: %s" % (drv['DriverAttributes']['Version'],))
        print("Beta: %s" % (bool(int(drv['DriverAttributes']['IsBeta'])),))
        print("WHQL: %s" % (bool(int(drv['DriverAttributes']['IsWHQL'])),))
        print("URL: %s" % (drv['DriverAttributes']['DownloadURLAdmin'],))
    else:
        json.dump(drv, sys.stdout, indent=4)
        sys.stdout.flush()


if __name__ == '__main__':
    main()
