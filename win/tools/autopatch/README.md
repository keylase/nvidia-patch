autopatch
=========

This tool is intended for internal usage.

This script accepts path to Nvidia Drivers installer, makes .1337 patch and saves it in appropriate location in your working copy of this repo. All you have to do then is to test patch, stage it for commit and push it. Optionally you can just save patch to stdout.

## Requirements

* Python 3.2+
* 7zip CLI utility

## Synopsys

```
$ ./autopatch.py --help
usage: autopatch.py [-h] [-7 SEVENZIP] [-T TARGET] [-N TARGET_NAME]
                    [-S SEARCH] [-R REPLACEMENT] [-o]
                    installer_file [installer_file ...]

Generates .1337 patch for Nvidia drivers for Windows

positional arguments:
  installer_file        location of installer executable(s)

optional arguments:
  -h, --help            show this help message and exit
  -7 SEVENZIP, --7zip SEVENZIP
                        location of 7-zip `7z` executable (default: 7z)
  -T TARGET, --target TARGET
                        target location in archive (default:
                        Display.Driver/nvcuvid64.dl_)
  -N TARGET_NAME, --target-name TARGET_NAME
                        name of installed target file. Used for patch header
                        (default: nvcuvid.dll)
  -S SEARCH, --search SEARCH
                        representation of search pattern binary string
                        (default: FF908000000084C07408)
  -R REPLACEMENT, --replacement REPLACEMENT
                        representation of replacement binary string (default:
                        FF908000000084C09090)
  -o, --stdout          output into stdout (default: False)
```
