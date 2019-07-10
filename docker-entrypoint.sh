#!/bin/sh

echo "/patched-lib" > /etc/ld.so.conf.d/000-patched-lib.conf && \
PATCH_OUTPUT_DIR=/patched-lib /usr/local/bin/patch.sh && \
cd /patched-lib && \
for f in * ; do
    suffix="${f##*.so}"
    name="$(basename "$f" "$suffix")"
    ln -s "$f" "$name"
    ln -s "$f" "$name.1"
done && \
ldconfig
[ "$OLDPWD" ] && cd -
exec "$@"
