#!/usr/bin/env bash

ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -f lavfi -i testsrc -t 50 -c:a copy -c:v h264_nvenc -b:v 1M -f null - -c:a copy -c:v h264_nvenc -b:v 2M -f null - -c:a copy -c:v h264_nvenc -b:v 3M -f null - -c:a copy -c:v h264_nvenc -b:v 4M -f null - -c:a copy -c:v h264_nvenc -b:v 5M -f null - -c:a copy -c:v h264_nvenc -b:v 6M -f null - -c:a copy -c:v h264_nvenc -b:v 7M -f null - -c:a copy -c:v h264_nvenc -b:v 8M -f null - -c:a copy -c:v h264_nvenc -b:v 9M -f null -
