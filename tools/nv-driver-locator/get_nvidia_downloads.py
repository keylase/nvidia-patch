#!/usr/bin/env python3

import urllib.request
import urllib.error
import urllib.parse
import codecs
import enum
from bs4 import BeautifulSoup

USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64; rv:65.0) '\
             'Gecko/20100101 Firefox/65.0'


@enum.unique
class OS(enum.Enum):
    Linux_32 = 11
    Linux_64 = 12
    Windows7_32 = 18
    Windows7_64 = 19
    Windows10_32 = 56
    Windows10_64 = 57
    WindowsServer2012R2_32 = 32
    WindowsServer2012R2_64 = 44
    WindowsServer2016 = 74
    WindowsServer2019 = 119

    def __str__(self):
        return self.name

    def __contains__(self, e):
        return e in self.__members__


@enum.unique
class CertLevel(enum.Enum):
    All = ''
    Beta = 0
    Certified = 1
    ODE = 2
    QNF = 3
    CRD = 4

    def __str__(self):
        return self.name

    def __contains__(self, e):
        return e in self.__members__


@enum.unique
class Product(enum.Enum):
    GeForce = (107, 879)
    GeForceMobile = (111, 890)
    Quadro = (73, 844)
    QuadroMobile = (74, 875)

    def __str__(self):
        return self.name

    def __contains__(self, e):
        return e in self.__members__


@enum.unique
class DriverType(enum.Enum):
    Standard = 0
    DCH = 1

    def __str__(self):
        return self.name

    def __contains__(self, e):
        return e in self.__members__


@enum.unique
class DriverLanguage(enum.Enum):
    English = 1

    def __str__(self):
        return self.name

    def __contains__(self, e):
        return e in self.__members__


@enum.unique
class CUDAToolkitVersion(enum.Enum):
    Nothing = 0
    v10_0 = 20

    def __str__(self):
        return self.name

    def __contains__(self, e):
        return e in self.__members__


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
    parser.add_argument("-o", "--os",
                        type=OS.__getitem__,
                        choices=list(OS),
                        default=OS.Linux_64,
                        help="OS")
    parser.add_argument("-p", "--product",
                        type=Product.__getitem__,
                        choices=list(Product),
                        default=Product.GeForce,
                        help="GPU Product type")
    parser.add_argument("-c", "--certification-level",
                        type=CertLevel.__getitem__,
                        choices=list(CertLevel),
                        default=CertLevel.All,
                        help="driver certification level")
    parser.add_argument("-D", "--dch",
                        help="Query DCH driver instead of Standard driver",
                        default=DriverType.Standard,
                        const=DriverType.DCH,
                        action="store_const")
    parser.add_argument("-T", "--timeout",
                        type=check_positive_float,
                        default=10.,
                        help="timeout for network operations")
    args = parser.parse_args()
    return args


def issue_request(query_obj, timeout=10):
    ENDPOINT = 'https://www.nvidia.com/Download/processFind.aspx'
    url = ENDPOINT + '?' + urllib.parse.urlencode(query_obj)
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


def get_drivers(*,
                os=OS.Linux_64,
                product=Product.GeForce,
                certlevel=CertLevel.All,
                driver_type=DriverType.Standard,
                lang=DriverLanguage.English,
                cuda_ver=CUDAToolkitVersion.Nothing,
                timeout=10):
    psid, pfid = product.value
    query = {
        'psid': psid,
        'pfid': pfid,
        'osid': os.value,
        'lid': lang.value,
        'whql': certlevel.value,
        'lang': 'en-us',
        'ctk': cuda_ver.value,
    }
    if os is OS.Windows10_64:
        query['dtcid'] = driver_type.value
    doc = issue_request(query, timeout)
    soup = BeautifulSoup(doc, 'html.parser')
    if soup.find(class_='contentBucketMainContent') is None:
        return []
    driverlistrows = list(
        soup.find(class_='contentBucketMainContent')
            .find_all('tr', id='driverList'))
    if not driverlistrows:
        return []
    header = soup.find('td', class_='gridHeader').parent

    def normalize_header(td):
        return td.string.replace(' ', '').lower()

    label_tuple = tuple(normalize_header(td) for td in header('td'))

    def parse_content_td(td):
        s = list(td.strings)
        return max(s, key=len).strip() if s else ''

    res = [dict(zip(label_tuple, (parse_content_td(td) for td in tr('td'))
                    )) for tr in driverlistrows]
    return res


def main():
    import pprint
    args = parse_args()
    pprint.pprint(get_drivers(os=args.os,
                              product=args.product,
                              certlevel=args.certification_level,
                              driver_type=args.dch,
                              timeout=args.timeout))


if __name__ == '__main__':
    main()
