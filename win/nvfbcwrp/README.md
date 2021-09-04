nvfbcwrp
========

Wrapper for `NvFBC64.dll` library which injects private keys into `NvFBC_CreateEx` calls in order to enable NvFBC on customer-grade hardware (like GeForce cards) for all NvFBC-targeted applications. It should work at least with applications built with Nvidia Capture SDK versions 5.0 to 7.1.

## Usage

1. Obtain `nvfbcwrp64.dll` and `nvfbcwrp32.dll` files. You may build them yourself with MSVS 2019 or download latest release here: [nvfbcwrp64.dll](https://gist.github.com/Snawoot/17b14e7ce0f7412b91587c2723719eff/raw/e8e9658fd20751ad875477f37b49ea158ece896d/nvfbcwrp64.dll), [nvfbcwrp32.dll](https://gist.github.com/Snawoot/17b14e7ce0f7412b91587c2723719eff/raw/e8e9658fd20751ad875477f37b49ea158ece896d/nvfbcwrp32.dll).
2. Backup your `%WINDIR%\system32\NvFBC64.dll` and `%WINDIR%\SysWOW64\NvFBC.dll` files.
3. Rename file `%WINDIR%\system32\NvFBC64.dll` to `%WINDIR%\system32\NvFBC64_.dll`
4. Rename file `%WINDIR%\SysWOW64\NvFBC.dll` to `%WINDIR%\SysWOW64\NvFBC_.dll`
5. Rename `nvfbcwrp64.dll` and put it to `%WINDIR%\system32\NvFBC64.dll` (on the original place of renamed `NvFBC64.dll` library).
6. Rename `nvfbcwrp32.dll` and put it to `%WINDIR%\SysWOW64\NvFBC.dll` (on the original place of renamed `NvFBC.dll` library).
7. Restart any applications using this library. That's it.

This procedure has to be repeated after any driver reinstall/update, so keep your copies of `nvfbcwrp64.dll` and `nvfbcwrp32.dll` files.

## Advanced Usage

`nvfbcwrp` allows user to capture and replay `privateData` used by other NvFBC applications (like GeForce Experience, Shadow Play and so on). It may be useful if built-in `privateData` will render invalid for some reason. Wrapper recognizes two environment variables:

* `NVFBCWRP_DUMP_DIR` - output directory for dumps of `privateData` sent by applications.
* `NVFBCWRP_PRIVDATA_FILE` - name of file with `privateData` which should be used instead of default built-in vector. These files can be produced as output of `NVFBCWRP_DUMP_DIR` option. If file is not found or can't be loaded, default magic vector is used.

Hence, if default magic baked into nvfbcwrp doesn't work for you, you have to:

1. Specify environment variable `NVFBCWRP_DUMP_DIR` in your configuration with path to existing writable directory. Here is a [guide](http://web.archive.org/web/20191207221102/https://docs.oracle.com/en/database/oracle/r-enterprise/1.5.1/oread/creating-and-modifying-environment-variables-on-windows.html) about environment variables edit. It's sufficient to add "user" environment variable.
2. Run some NvFBC application with valid `privateData` keys and initiate recording session.
3. Grab some output file and specify it's path in `NVFBCWRP_PRIVDATA_FILE`. At this point you can unset `NVFBCWRP_DUMP_DIR` to stop `privateData` capture.

## 3rd-party software

For some software (e.g Steam) it is also needed to add registry value to use NvFBC, which you can do by running:
```batch
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v NVFBCEnable /d 1 /t REG_DWORD /f
```
(reboot / driver restart required to take effect)
