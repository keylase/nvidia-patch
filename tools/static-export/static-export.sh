#!/usr/bin/env bash

set -euo pipefail

(( $# == 1 )) || {
    >&2 echo "Usage: $0 <export dir>"
    exit 2
}

mkdir -p "$1"
EXPORT_DIR="$(realpath "$1")"

REPO_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../..")"

CONVERTER_PATH="${CONVERTER_PATH:-$REPO_DIR/../markdown-to-html-github-style/convert.js}"
CONVERTER_PATH="$(realpath "$CONVERTER_PATH")"

[[ -s "$CONVERTER_PATH" ]] || {
    >&2 echo "convert.js not found"
    exit 1
}

pushd "$REPO_DIR"
git archive HEAD | tar x -C "$EXPORT_DIR"
popd
pushd "$EXPORT_DIR"
./tools/readme-autogen/readme_autogen.py -R ""
node "$CONVERTER_PATH" "NVENC and NvFBC patches for Nvidia drivers"
mv -v README.html index.html
pushd win
node "$CONVERTER_PATH" "NVENC and NvFBC patches for Windows Nvidia drivers"
mv -v README.html index.html
popd
popd
