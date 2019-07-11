#!/bin/sh

echo "/patched-lib" > /etc/ld.so.conf.d/000-patched-lib.conf && \
mkdir -p "/patched-lib" && \
PATCH_OUTPUT_DIR=/patched-lib /usr/local/bin/patch.sh && \
cd /patched-lib && \
for f in * ; do
    suffix="${f##*.so}"
    name="$(basename "$f" "$suffix")"
    [ -h "$name" ] || ln -sf "$f" "$name"
    [ -h "$name" ] || ln -sf "$f" "$name.1"
done && \
ldconfig
[ "$OLDPWD" ] && cd -
exec "$@"
