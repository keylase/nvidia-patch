nvfbcwrp
========

Wrapper for `NvFBC64.dll` library which injects private keys into `NvFBC_CreateEx` calls in order to enable NvFBC on customer-grade hardware (like GeForce cards) for all NvFBC-targeted applications. It should work at least with applications built with Nvidia Capture SDK versions 5.0 to 7.1.

## Usage

1. Obtain `nvfbcwrp64.dll` and `nvfbcwrp32.dll` files. You may build them yourself with MSVS 2019 or download latest release here: [nvfbcwrp64.dll](https://gist.github.com/Snawoot/2d78c569b5ffb29080cf9bfca401adfa/raw/166c5e10f8301000c171d5f59cc2ae0b551cd1b3/nvfbcwrp64.dll), [nvfbcwrp32.dll](https://gist.github.com/Snawoot/2d78c569b5ffb29080cf9bfca401adfa/raw/166c5e10f8301000c171d5f59cc2ae0b551cd1b3/nvfbcwrp32.dll).
2. Backup your `%WINDIR\system32\NvFBC64.dll` and `%WINDIR\SysWOW64\NvFBC.dll` files.
3. Rename file `%WINDIR\system32\NvFBC64.dll` to `%WINDIR\system32\NvFBC64_.dll`
4. Rename file `%WINDIR\SysWOW64\NvFBC.dll` to `%WINDIR\SysWOW64\NvFBC_.dll`
5. Rename `nvfbcwrp64.dll` and put it to `%WINDIR\system32\NvFBC64.dll` (on the original place of renamed `NvFBC64.dll` library).
6. Rename `nvfbcwrp32.dll` and put it to `%WINDIR\SysWOW64\NvFBC.dll` (on the original place of renamed `NvFBC.dll` library).
7. Restart any applications using this library. That's it.

This procedure has to be repeated after any driver reinstall/update, so keep your copies of `nvfbcwrp64.dll` and `nvfbcwrp32.dll` files.
