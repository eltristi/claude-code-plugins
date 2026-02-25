#!/usr/bin/env bash
# extract-frames.sh — Extract frames from a video using FFMPEG
#
# Usage:
#   extract-frames.sh <video_path> [fps] [max_frames] [output_dir]
#
# Arguments:
#   video_path   Path to local video file (required)
#   fps          Frames per second to extract (default: 1)
#   max_frames   Maximum number of frames to extract (default: 60)
#   output_dir   Directory for extracted frames (default: /tmp/video-frames-<hash>)
#
# Output:
#   Prints JSON with extraction metadata to stdout:
#   {
#     "output_dir": "/tmp/video-frames-abc123",
#     "frame_count": 42,
#     "duration_seconds": 120.5,
#     "fps_used": 1,
#     "video_width": 1920,
#     "video_height": 1080
#   }

set -euo pipefail

VIDEO_PATH="${1:?Usage: extract-frames.sh <video_path> [fps] [max_frames] [output_dir]}"
FPS="${2:-1}"
MAX_FRAMES="${3:-60}"

# Generate deterministic output dir from video path hash
VIDEO_HASH=$(echo -n "$VIDEO_PATH" | shasum -a 256 | cut -c1-12)
OUTPUT_DIR="${4:-/tmp/video-frames-${VIDEO_HASH}}"

# Validate dependencies
for cmd in ffmpeg ffprobe; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is not installed. Install with: brew install ffmpeg" >&2
    exit 1
  fi
done

# Validate video file
if [[ ! -f "$VIDEO_PATH" ]]; then
  echo "Error: Video file not found: $VIDEO_PATH" >&2
  exit 1
fi

# Get video metadata
DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$VIDEO_PATH" 2>/dev/null | head -1)
if [[ -z "$DURATION" || "$DURATION" == "N/A" ]]; then
  echo "Error: Could not determine video duration. File may be corrupted or unsupported." >&2
  exit 1
fi

WIDTH=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width -of csv=p=0 "$VIDEO_PATH" 2>/dev/null | head -1)
HEIGHT=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$VIDEO_PATH" 2>/dev/null | head -1)

# Calculate expected frames and adjust FPS if needed
EXPECTED_FRAMES=$(awk "BEGIN {printf \"%d\", $DURATION * $FPS}" 2>/dev/null)

ACTUAL_FPS="$FPS"
if [[ "$EXPECTED_FRAMES" -gt "$MAX_FRAMES" ]]; then
  # Adjust FPS to stay within max_frames
  # Use awk for floating point division
  ACTUAL_FPS=$(awk "BEGIN {printf \"%.4f\", $MAX_FRAMES / $DURATION}" 2>/dev/null)
fi

# Create output directory (clean if exists)
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Extract frames
# Scale down large videos to save disk and context (max 1280px wide)
SCALE_FILTER=""
if [[ -n "$WIDTH" ]] && [[ "$WIDTH" -gt 1280 ]]; then
  SCALE_FILTER=",scale=1280:-2"
fi

ffmpeg -v quiet -i "$VIDEO_PATH" \
  -vf "fps=${ACTUAL_FPS}${SCALE_FILTER}" \
  -frame_pts 1 \
  -q:v 3 \
  "$OUTPUT_DIR/frame_%05d.jpg" 2>/dev/null

# Count extracted frames
FRAME_COUNT=$(find "$OUTPUT_DIR" -name "frame_*.jpg" -type f | wc -l | tr -d ' ')

# Generate timestamp mapping
# Each frame corresponds to a timestamp based on the FPS used
FRAME_IDX=0
TIMESTAMP_FILE="$OUTPUT_DIR/timestamps.txt"
> "$TIMESTAMP_FILE"
for frame_file in "$OUTPUT_DIR"/frame_*.jpg; do
  [[ -f "$frame_file" ]] || continue
  TIMESTAMP=$(awk "BEGIN {printf \"%.1f\", $FRAME_IDX / $ACTUAL_FPS}" 2>/dev/null)
  BASENAME=$(basename "$frame_file")
  echo "${BASENAME} ${TIMESTAMP}s" >> "$TIMESTAMP_FILE"
  FRAME_IDX=$((FRAME_IDX + 1))
done

# Output metadata as JSON
cat <<EOF
{
  "output_dir": "$OUTPUT_DIR",
  "frame_count": $FRAME_COUNT,
  "duration_seconds": $DURATION,
  "fps_used": $ACTUAL_FPS,
  "video_width": ${WIDTH:-0},
  "video_height": ${HEIGHT:-0},
  "timestamp_file": "$TIMESTAMP_FILE"
}
EOF
