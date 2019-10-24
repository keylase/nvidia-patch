autopatch
=========

This tool is intended for internal usage.

This script accepts path to Nvidia Drivers installer file(s), makes .1337 patch and saves it in appropriate location in your working copy of this repo. All you have to do then is to test patch, stage it for commit and push it. Optionally you can just save patch to stdout.

If you have already extracted binary files, you can supply them directly to autopatch running in direct mode `-D` option. In this case number of input files must match count of replacement patterns.

Note: when command line options with multiple possible arguments supplied (like patterns or targets), you must separate them from positional arguments (input files) with a double dash (`--`). Example: `./autopatch.py -P nvcuvid32.1337 nvcuvid64.1337 -T nvcuvid32.dll nvcuvid64.dll -- setup1.exe setup2.exe`.

## Requirements

* Python 3.2+
* 7zip CLI utility

## Synopsys

```
usage: autopatch.py [-h] [-7 SEVENZIP] [-T TARGET [TARGET ...]]
                    [-N TARGET_NAME [TARGET_NAME ...]]
                    [-P PATCH_NAME [PATCH_NAME ...]] [-S SEARCH [SEARCH ...]]
                    [-R REPLACEMENT [REPLACEMENT ...]] [-o] [-D]
                    installer_file [installer_file ...]

Generates .1337 patch for Nvidia drivers for Windows

positional arguments:
  installer_file        location of installer executable(s)

optional arguments:
  -h, --help            show this help message and exit
  -7 SEVENZIP, --7zip SEVENZIP
                        location of 7-zip `7z` executable (default: 7z)
  -T TARGET [TARGET ...], --target TARGET [TARGET ...]
                        target location(s) in archive (default:
                        ['Display.Driver/nvcuvid64.dl_',
                        'Display.Driver/nvcuvid32.dl_'])
  -N TARGET_NAME [TARGET_NAME ...], --target-name TARGET_NAME [TARGET_NAME ...]
                        name(s) of installed target file. Used for patch
                        header (default: ['nvcuvid.dll', 'nvcuvid.dll'])
  -P PATCH_NAME [PATCH_NAME ...], --patch-name PATCH_NAME [PATCH_NAME ...]
                        relative filename(s) of generated patch(es) (default:
                        ['nvcuvid64.1337', 'nvcuvid32.1337'])
  -S SEARCH [SEARCH ...], --search SEARCH [SEARCH ...]
                        representation of search pattern(s) binary string
                        (default: ['FF909800000084C075', '8B404CFFD084C075'])
  -R REPLACEMENT [REPLACEMENT ...], --replacement REPLACEMENT [REPLACEMENT ...]
                        representation of replacement(s) binary string
                        (default: ['FF90980000000C0175', '8B404CFFD00C0175'])
  -o, --stdout          output into stdout (default: False)
  -D, --direct          supply patched library directly instead of installer
                        file. Implies --stdout option. (default: False)
```
