#!/bin/bash

# NVENC Multi-Session Test Script
# This script tests NVIDIA NVENC hardware encoding capabilities by running multiple simultaneous encoding sessions.
# It demonstrates the removal of the 2-session limit on consumer GPUs through the NVENC patch.

# Default settings
DURATION=10
RESOLUTION="1920x1080"
FRAMERATE=30
BITRATE="5M"
NUM_SESSIONS=8
PRESET="p7"  # p1 (fastest) to p7 (slowest)
CODEC="h264_nvenc"  # can be h264_nvenc, hevc_nvenc, or av1_nvenc

# Function to display script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n NUMBER    Number of simultaneous sessions (default: 8)"
    echo "  -d DURATION  Test duration in seconds (default: 10)"
    echo "  -r RES      Resolution in WxH format (default: 1920x1080)"
    echo "  -f FPS      Framerate (default: 30)"
    echo "  -b BITRATE  Target bitrate (default: 5M)"
    echo "  -p PRESET   NVENC preset p1-p7 (default: p7)"
    echo "  -c CODEC    Encoder codec (h264_nvenc, hevc_nvenc, av1_nvenc) (default: h264_nvenc)"
    echo "  -h          Display this help message"
}

# Parse command line arguments
while getopts "n:d:r:f:b:p:c:h" opt; do
    case $opt in
        n) NUM_SESSIONS="$OPTARG" ;;
        d) DURATION="$OPTARG" ;;
        r) RESOLUTION="$OPTARG" ;;
        f) FRAMERATE="$OPTARG" ;;
        b) BITRATE="$OPTARG" ;;
        p) PRESET="$OPTARG" ;;
        c) CODEC="$OPTARG" ;;
        h) usage; exit 0 ;;
        ?) usage; exit 1 ;;
    esac
done

# Function to start an encoding session
encode_session() {
    local session_num=$1
    local output_file="output_${session_num}.mp4"
    local log_file="session_${session_num}.log"
    
    # Add session info to the test pattern
    local text="Session ${session_num} - ${CODEC} - ${PRESET}"
    
    ffmpeg -f lavfi -i "testsrc=duration=${DURATION}:size=${RESOLUTION}:rate=${FRAMERATE}" \
        -c:v "${CODEC}" \
        -preset "${PRESET}" \
        -b:v "${BITRATE}" \
        -y "${output_file}" > "${log_file}" 2>&1 &
        
    echo "Started session $session_num (PID: $!)"
}

echo "Starting multiple NVENC encoding sessions..."
echo "Configuration:"
echo "- Number of sessions: ${NUM_SESSIONS}"
echo "- Resolution: ${RESOLUTION}"
echo "- Framerate: ${FRAMERATE}"
echo "- Duration: ${DURATION}s"
echo "- Bitrate: ${BITRATE}"
echo "- Preset: ${PRESET}"
echo "- Codec: ${CODEC}"
echo

# Start encoding sessions
for i in $(seq 1 ${NUM_SESSIONS}); do
    encode_session $i
    sleep 1  # Brief pause between session starts
done

# Wait for all sessions to complete
wait

echo -e "\nAll encoding sessions completed\n"

# Print session statistics
echo "Encoding Statistics:"
for i in $(seq 1 ${NUM_SESSIONS}); do
    output_file="output_${i}.mp4"
    log_file="session_${i}.log"
    if [ -f "${output_file}" ]; then
        size=$(du -h "${output_file}" | cut -f1)
        # Extract encoding speed from log file
        speed=$(grep "speed=" "${log_file}" | tail -n1 | sed 's/.*speed=\s*\([0-9.]*\)x/\1/')
        echo "Session $i: Size=${size}, Speed=${speed}x"
    else
        echo "Session $i: Failed to create output file"
    fi
done 