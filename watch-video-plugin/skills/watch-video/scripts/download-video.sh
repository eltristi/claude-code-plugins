#!/usr/bin/env bash
# download-video.sh — Download a video from a URL to a local temp file
#
# Usage:
#   download-video.sh <url>
#
# Supports:
#   - Direct video URLs (.mp4, .mov, .webm, .avi, .mkv)
#   - YouTube, Loom, Vimeo via yt-dlp (if installed)
#   - Asana/Linear attachment URLs via curl
#
# Output:
#   Prints the local file path of the downloaded video to stdout

set -euo pipefail

URL="${1:?Usage: download-video.sh <url>}"

# Generate temp filename from URL hash
URL_HASH=$(echo -n "$URL" | shasum -a 256 | cut -c1-12)
TEMP_DIR="/tmp/video-download-${URL_HASH}"
mkdir -p "$TEMP_DIR"

# Detect URL type
is_streaming_platform() {
  local url="$1"
  [[ "$url" =~ (youtube\.com|youtu\.be|vimeo\.com|loom\.com|dailymotion\.com|twitch\.tv) ]]
}

is_direct_video() {
  local url="$1"
  [[ "$url" =~ \.(mp4|mov|webm|avi|mkv|m4v|flv|wmv)(\?|$) ]]
}

if is_streaming_platform "$URL"; then
  # Use yt-dlp for streaming platforms
  if ! command -v yt-dlp &>/dev/null; then
    echo "Error: yt-dlp is required for this URL. Install with: brew install yt-dlp" >&2
    exit 1
  fi

  OUTPUT_FILE="${TEMP_DIR}/video.mp4"
  yt-dlp \
    --quiet \
    --no-warnings \
    -f "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]/best" \
    --merge-output-format mp4 \
    -o "$OUTPUT_FILE" \
    "$URL" 2>/dev/null

  if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "Error: yt-dlp failed to download video from: $URL" >&2
    exit 1
  fi

  echo "$OUTPUT_FILE"

elif is_direct_video "$URL"; then
  # Direct download with curl
  EXTENSION="${URL##*.}"
  EXTENSION="${EXTENSION%%\?*}"
  OUTPUT_FILE="${TEMP_DIR}/video.${EXTENSION}"

  curl -sL -o "$OUTPUT_FILE" "$URL"

  if [[ ! -s "$OUTPUT_FILE" ]]; then
    echo "Error: Failed to download video from: $URL" >&2
    exit 1
  fi

  echo "$OUTPUT_FILE"

else
  # Try curl for any other URL (Asana/Linear attachments, etc.)
  OUTPUT_FILE="${TEMP_DIR}/video.mp4"

  curl -sL -o "$OUTPUT_FILE" "$URL"

  # Verify it's actually a video by checking with ffprobe
  if ! ffprobe -v quiet "$OUTPUT_FILE" 2>/dev/null; then
    echo "Error: Downloaded file is not a valid video: $URL" >&2
    rm -f "$OUTPUT_FILE"
    exit 1
  fi

  echo "$OUTPUT_FILE"
fi
