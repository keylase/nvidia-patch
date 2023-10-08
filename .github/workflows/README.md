# GitHub Actions usage

To create patches to a new driver version simply create a new release with the following name schema:
- For DCH: `win-dch-536.67`
- For Studio: `win-studio-536.67`
- If you need to rerun append `-{try}` e.g. `win-dch-536.67-2`

Tagname same as release name.

If the patch file exist for a version, they will get deleted and recreated.   

The patches will be added as asset to the release.


> Currently only for windows10 patches