#!/usr/bin/env pwsh

ffmpeg.exe -y -hwaccel cuda -hwaccel_output_format cuda -f lavfi -i testsrc -t 50 -vf hwupload -fps_mode passthrough -c:a copy -c:v h264_nvenc -b:v 4M -f null - -vf hwupload -fps_mode passthrough -c:a copy -c:v h264_nvenc -b:v 1M -f null - -vf hwupload -fps_mode passthrough -c:a copy -c:v h264_nvenc -b:v 8M -f null - -vf hwupload -fps_mode passthrough -c:a copy -c:v h264_nvenc -b:v 6M -f null - -vf hwupload -fps_mode passthrough -c:a copy -c:v h264_nvenc -b:v 5M -f null - -vf hwupload -fps_mode passthrough -c:a copy -c:v h264_nvenc -b:v 7M -f null -
