from enum import IntEnum
import os.path

class Product(IntEnum):
    GeForce = 10
    Quadro = 20

class WinSeries(IntEnum):
    win10 = 10
    win7 = 20
    ws2012 = 30
    ws2016 = 40

BASE_PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             "templates")
DATAFILE_PATH = os.path.join(BASE_PATH,
                             "..", "..", "drivers.json")
LINUX_README_PATH = os.path.join(BASE_PATH,
                                 "..", "..", "README.md")
WINDOWS_README_PATH = os.path.join(BASE_PATH,
                                 "..", "..", "win", "README.md")

ENCODING='utf-8'
