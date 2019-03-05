#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=ffmpegNull10StreamsSilent.exe
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <WinAPIFiles.au3>
$ffmpegCMD = ("-y -f lavfi -i nullsrc=s=256x256:d=5 -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null - -c:v h264_nvenc -f null -")
run(@scriptdir & "\" & "ffmpeg.exe" & " " & $ffmpegCMD,@ScriptDir, @SW_HIDE, $STDERR_CHILD+$STDOUT_CHILD)
