#!/bin/bash
input=$1
output=$2
if [ -z $1 ]; then
  echo "Require params - example: ./patch.sh <input file> <output file>"
  exit
fi
sed 's/\x85\xC0\x89\xC5\x75\x18/\x29\xC0\x89\xC5\x90\x90/g' $input > $output

