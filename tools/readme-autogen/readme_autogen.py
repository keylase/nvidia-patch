#!/usr/bin/env python3

import json
import os.path
from string import Template
from enum import IntEnum
from itertools import groupby
from functools import lru_cache

BASE_PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "templates")
DATAFILE_PATH = os.path.join(BASE_PATH,
                             "..", "..", "drivers.json")
LINUX_README_PATH = os.path.join(BASE_PATH,
                                 "..", "..", "README.md")
WINDOWS_README_PATH = os.path.join(BASE_PATH,
                                 "..", "..", "win", "README.md")
ENCODING="utf-8"

class Product(IntEnum):
    GeForce = 10
    Quadro = 20

class WinSeries(IntEnum):
    win10 = 10
    win7 = 20
    ws2012 = 30
    ws2016 = 40

PRODUCT_LABELS = {
    Product.GeForce: "GeForce",
    Product.Quadro: "Quadro",
}

WIN_SERIES_LABELS = {
    WinSeries.win10: "Windows 10",
    WinSeries.win7: "Windows 7, Windows 8, Windows 8.1",
    WinSeries.ws2012: "Windows Server 2008R2, 2012, 2012R2",
    WinSeries.ws2016: "Windows Server 2016, 2019",
}

@lru_cache(maxsize=None)
def template(filename, strip_newlines=False):
    filename = os.path.join(TEMPLATE_PATH, filename)
    with open(filename, encoding=ENCODING) as f:
        text = f.read()
        if strip_newlines:
            text = text.rstrip('\r\n')
        t = Template(text)
    return t

def version_key_fun(ver):
    return tuple(map(int, ver.split('.')))

def find_driver(drivers, version, low=0, hi=None):
    """ Bisect search on sorted linux drivers list """
    if hi is None:
        hi = len(drivers)
    L = hi - low
    if L == 0:
        return None
    elif L == 1:
        return drivers[low] if drivers[low]['version'] == version else None
    else:
        vkf_left = version_key_fun(drivers[low + L // 2]['version'])
        vkf_right = version_key_fun(version)
        if vkf_left < vkf_right:
            return find_driver(drivers, version, low + L // 2, hi)
        elif vkf_left > vkf_right:
            return find_driver(drivers, version, low, low + L // 2)
        else:
            return drivers[low + L // 2]

def linux_readme(data):
    master_tmpl = template('linux_readme_master.tmpl')
    nolink_row_tmpl = template('linux_nolink_row.tmpl', True)
    link_row_tmpl = template('linux_link_row.tmpl', True)
    drivers = sorted(data['drivers'],
                     key=lambda d: version_key_fun(d['version']))
    def row_gen():
        for drv in drivers:
            driver_url = drv.get('driver_url')
            t = nolink_row_tmpl if driver_url is None else link_row_tmpl
            yield t.substitute(driver_version=drv['version'],
                               driver_url=driver_url)
    version_list = "\n".join(row_gen())
    latest_version = drivers[-1]['version']
    example_driver = find_driver(drivers, data['example']['version'])
    example_driver_url = example_driver['driver_url']
    return master_tmpl.substitute(version_list=version_list,
                                  latest_version=latest_version,
                                  example_driver_url=example_driver_url,
                                  example_driver_version=example_driver['version'],
                                  example_driver_file=os.path.basename(example_driver_url))

def windows_driver_rows(drivers):
    driver_row_tmpl = template('windows_driver_row.tmpl', True)
    markdown_link_tmpl = template('markdown_link.tmpl', True)
    def row_gen():
        for d in drivers:
            product = PRODUCT_LABELS[Product[d['product']]]
            variant = d.get('variant')
            version_variant = d['version']
            version_variant += (" " + variant) if variant else ''
            patch64_url = d.get('patch64_url')
            patch32_url = d.get('patch32_url')
            driver_url = d.get('driver_url')
            patch64_link = markdown_link_tmpl.substitute(text="x64 library patch",
                                                         url=patch64_url) if patch64_url else ''
            patch32_link = markdown_link_tmpl.substitute(text="x86 library patch",
                                                         url=patch32_url) if patch32_url else ''
            driver_link = markdown_link_tmpl.substitute(text="Driver link",
                                                        url=driver_url) if driver_url else ''
            yield driver_row_tmpl.substitute(product=product,
                                             version_variant=version_variant,
                                             patch64_link=patch64_link,
                                             patch32_link=patch32_link,
                                             driver_link=driver_link)
    return "\n".join(row_gen())

def windows_product_sections(drivers):
    product_section_tmpl = template('windows_product_section.tmpl')
    def section_gen():
        for k, g in groupby(drivers, lambda d: Product[d['product']]):
            driver_rows = windows_driver_rows(g)
            yield product_section_tmpl.substitute(driver_rows=driver_rows)
    return '\n\n'.join(section_gen())

def windows_driver_table(drivers):
    os_section_tmpl = template('windows_os_section.tmpl', True)
    def section_gen():
        for k, g in groupby(drivers, lambda d: WinSeries[d['os']]):
            os = WIN_SERIES_LABELS[k]
            product_sections = windows_product_sections(g)
            yield os_section_tmpl.substitute(os=os,
                                             product_sections=product_sections)
    return '\n\n'.join(section_gen())

def windows_readme(data):
    master_tmpl = template('windows_readme_master.tmpl')
    def driver_key_fun(d):
        return ((WinSeries[d['os']], Product[d['product']]) +
                version_key_fun(d['version']) +
                (d.get('variant'),))
    drivers = sorted(data['drivers'], key=driver_key_fun)
    version_table = windows_driver_table(drivers)

    geforce_drivers = filter(lambda d: Product[d['product']] is Product.GeForce, drivers)
    quadro_drivers = filter(lambda d: Product[d['product']] is Product.Quadro, drivers)
    latest_geforce_version = max(geforce_drivers, default='xxx.xx',
                                 key=lambda d: version_key_fun(d['version']))['version']
    latest_quadro_version = max(quadro_drivers, default='xxx.xx',
                                key=lambda d: version_key_fun(d['version']))['version']
    return master_tmpl.substitute(version_table=version_table,
                                  latest_geforce_version=latest_geforce_version,
                                  latest_quadro_version=latest_quadro_version)

def main():
    with open(DATAFILE_PATH) as data_file:
        data = json.load(data_file)
    res = linux_readme(data['linux']['x86_64'])
    with open(LINUX_README_PATH, 'w', encoding=ENCODING) as out:
        out.write(res)
    res = windows_readme(data['win']['x86_64'])
    with open(WINDOWS_README_PATH, 'w', encoding=ENCODING) as out:
        out.write(res)

if __name__ == '__main__':
    main()
