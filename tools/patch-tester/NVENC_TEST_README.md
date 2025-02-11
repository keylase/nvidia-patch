# NVENC Multi-Session Test Script

This script demonstrates and tests NVIDIA NVENC hardware encoding capabilities with the NVENC patch. It allows running multiple simultaneous encoding sessions, beyond the default limit of 2 sessions on consumer GPUs.

## Features

- Test multiple simultaneous NVENC encoding sessions
- Support for H.264, HEVC (H.265), and AV1 NVENC encoders
- Configurable encoding parameters (resolution, bitrate, framerate, etc.)
- Detailed performance metrics for each session
- Session statistics reporting (file size and encoding speed)

## Requirements

- NVIDIA GPU with NVENC support
- NVIDIA drivers with NVENC patch applied
- FFmpeg compiled with NVENC support
- Linux operating system

## Usage

```bash
./test_nvenc.sh [OPTIONS]
```

### Options

- `-n NUMBER` : Number of simultaneous sessions (default: 8)
- `-d DURATION` : Test duration in seconds (default: 10)
- `-r RES` : Resolution in WxH format (default: 1920x1080)
- `-f FPS` : Framerate (default: 30)
- `-b BITRATE` : Target bitrate (default: 5M)
- `-p PRESET` : NVENC preset p1-p7 (default: p7)
- `-c CODEC` : Encoder codec (h264_nvenc, hevc_nvenc, av1_nvenc) (default: h264_nvenc)
- `-h` : Display help message

### Examples

1. Basic test with default settings:
```bash
./test_nvenc.sh
```

2. Test 12 simultaneous H.264 sessions:
```bash
./test_nvenc.sh -n 12
```

3. Test HEVC encoding with custom parameters:
```bash
./test_nvenc.sh -c hevc_nvenc -r 3840x2160 -b 20M -p p7
```

4. Test AV1 encoding:
```bash
./test_nvenc.sh -c av1_nvenc -n 4
```

## Output

The script generates:
1. Encoded video files (`output_1.mp4`, `output_2.mp4`, etc.)
2. Session log files with detailed encoding statistics (`session_1.log`, `session_2.log`, etc.)
3. Summary of encoding statistics including file sizes and encoding speeds

## Performance Metrics

The script reports two key metrics for each session:
1. Output file size
2. Encoding speed (relative to real-time, e.g., 6.5x means 6.5 times faster than real-time)

## Notes

1. Without the NVENC patch, consumer NVIDIA GPUs are limited to 2 simultaneous encoding sessions.
2. The actual number of possible simultaneous sessions depends on:
   - GPU model and capabilities
   - Available GPU memory
   - Encoding parameters (resolution, bitrate, etc.)
   - System resources

3. Performance considerations:
   - Encoding speed typically decreases as the number of simultaneous sessions increases
   - The p7 preset provides the best quality but slowest encoding speed
   - p1 preset offers the fastest encoding with lower quality
   - Higher resolutions and bitrates require more GPU resources

## Troubleshooting

1. If sessions fail to start, check:
   - NVIDIA driver installation
   - NVENC patch status
   - FFmpeg NVENC support
   - GPU resource usage

2. If performance is poor, try:
   - Reducing the number of simultaneous sessions
   - Using a faster preset (p1-p3)
   - Lowering resolution or bitrate
   - Checking GPU temperature and utilization

## Cleanup

To remove all test files:
```bash
rm -f output_*.mp4 session_*.log
``` 