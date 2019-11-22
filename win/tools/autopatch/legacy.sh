#!/bin/bash

DIR="$(dirname $0)"
AP="$DIR/autopatch.py"

"$AP"   -S 8BF085C0750549892FEB 8BD885DB75048937EB \
	-R 33C08BF0750549892FEB 33C08BD875048937EB \
	-T 'Display.Driver/nvencodeapi64.dl_' 'Display.Driver/nvencodeapi.dl_' \
	-N 'nvencodeapi64.dll' 'nvencodeapi.dll' \
	-P 'nvencodeapi64.1337' 'nvencodeapi.1337' \
	"$@"
