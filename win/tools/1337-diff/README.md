1337-diff
=========

This tool accepts two input files and produces patch (diff) in `.1337`-file format. This format is compatible with patches produced by [x64dbg](https://x64dbg.com/) and applied by [Win\_1337\_Apply\_Patch tool](https://github.com/Deltafox79/Win_1337_Apply_Patch).

This tool is intended for internal usage to automate routine tasks related to windows patches. Implementation is really slow and prefers code transparency and correctness over speed.

## Requirements

* Python 3

## Synopsys

```
$ ./1337-diff.py -h
usage: 1337-diff.py [-h] [-f FILENAME] [-l LIMIT]
                    ORIG_FILE PATCHED_FILE [OUTPUT_FILE]

Make .1337 patch file from original and patched files

positional arguments:
  ORIG_FILE             original file
  PATCHED_FILE          patched file
  OUTPUT_FILE           filename for patch output. Default: basename of
                        original filename with .1337 extension

optional arguments:
  -h, --help            show this help message and exit
  -f FILENAME, --header-filename FILENAME
                        filename specified in resulting patch header. Default:
                        basename of original filename.
  -l LIMIT, --limit LIMIT
                        stop after number of differences
```

## Example

```
$ ./1337-diff.py ~/w418.81/orig/nvcuvid.dll ~/w418.81/patched/nvcuvid.dll 
$ cat nvcuvid.1337 
>nvcuvid.dll
00000000000DE736:74->90
00000000000DE737:08->90$
```

Note no newline at the end of file and CRLF line breaks.
