nvfbcwrp
========

Wrapper for `NvFBC64.dll` library which injects private keys into `NvFBC_CreateEx` calls in order to enable NvFBC on customer-grade hardware (like GeForce cards) for all NvFBC-targeted applications. It should work at least with applications built with Nvidia Capture SDK versions 5.0 to 7.1.

## Usage

1. Obtain `nvfbcwrp.dll` file. You may build it yourself with MSVS 2019 or download latest release [here](https://gist.github.com/Snawoot/1edfbda9b0e91c46b6cc3d5a0e1e55a4/raw/ee2e4647753a731ac7b333a0c9681dc07d3ee0a1/nvfbcwrp.dll).
2. Backup your `%WINDIR\system32\NvFBC64.dll` file.
3. Rename file `%WINDIR\system32\NvFBC64.dll` to `%WINDIR\system32\NvFBC64_.dll`
4. Put `nvfbcwrp.dll` to `%WINDIR\system32\NvFBC64.dll` (on the original place of renamed `NvFBC64.dll` library).
5. Restart any applications using this library. That's it.
