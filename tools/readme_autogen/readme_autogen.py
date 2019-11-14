#!/usr/bin/env python3

import json
import os.path
from string import Template
from pprint import pprint

BASE_PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "templates")
DATAFILE_PATH = os.path.join(BASE_PATH,
                             "..", "..", "drivers.json")
LINUX_README_PATH = os.path.join(BASE_PATH,
                                 "..", "..", "README.md")
ENCODING="utf-8"

def template(filename):
    filename = os.path.join(TEMPLATE_PATH, filename)
    with open(filename, encoding=ENCODING) as f:
        t = Template(f.read())
    return t

def version_key_fun(ver):
    return tuple(map(int, ver.split('.')))

def find_driver(drivers, version, low=0, hi=None):
    """ Bisect search on sorted drivers list """
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
    master_tmpl = template("linux_readme_master.tmpl")
    linux_nolink_row_tmpl = template('linux_nolink_row.tmpl')
    linux_link_row_tmpl = template('linux_link_row.tmpl')
    drivers = sorted(data['drivers'],
                     key=lambda d: version_key_fun(d['version']))
    def row_gen():
        for drv in drivers:
            driver_url = drv.get('driver_url')
            t = linux_nolink_row_tmpl if driver_url is None else linux_link_row_tmpl
            yield t.substitute(driver_version=drv['version'],
                               driver_url=driver_url).rstrip('\r\n')
    version_list = "\n".join(row_gen())
    latest_version = drivers[-1]['version']
    example_driver = find_driver(drivers, data['example']['version'])
    example_driver_url = example_driver['driver_url']
    return master_tmpl.substitute(version_list=version_list,
                                  latest_version=latest_version,
                                  example_driver_url=example_driver_url,
                                  example_driver_version=example_driver['version'],
                                  example_driver_file=os.path.basename(example_driver_url))

def main():
    with open(DATAFILE_PATH) as data_file:
        data = json.load(data_file)
    res = linux_readme(data['linux']['x86_64'])
    with open(LINUX_README_PATH, 'w', encoding=ENCODING) as out:
        out.write(res)

if __name__ == '__main__':
    main()
