import os.path
from string import Template
from functools import lru_cache

from constants import TEMPLATE_PATH, ENCODING, WinSeries, Product

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

def find_driver(drivers, key, keyfun, low=0, hi=None):
    """ Bisect search on sorted linux drivers list """
    if hi is None:
        hi = len(drivers)
    L = hi - low
    if L == 0:
        return None
    elif L == 1:
        return drivers[low] if keyfun(drivers[low]) == key else None
    else:
        middle_key = keyfun(drivers[low + L // 2])
        if middle_key < key:
            return find_driver(drivers, key, keyfun, low + L // 2, hi)
        elif middle_key > key:
            return find_driver(drivers, key, keyfun, low, low + L // 2)
        else:
            return drivers[low + L // 2]

def linux_driver_key(driver):
    return version_key_fun(driver['version'])

def windows_driver_key(driver):
    return ((WinSeries[driver['os']], Product[driver['product']]) +
            version_key_fun(driver['version']) +
            (driver.get('variant'),))
