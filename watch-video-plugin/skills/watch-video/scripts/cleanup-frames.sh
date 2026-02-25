#!/usr/bin/env bash
# cleanup-frames.sh — Clean up extracted frames and downloaded videos
#
# Usage:
#   cleanup-frames.sh [specific_dir]
#
# Without arguments: cleans all /tmp/video-frames-* and /tmp/video-download-* dirs
# With argument: cleans the specified directory only

set -euo pipefail

if [[ $# -gt 0 ]]; then
  # Clean specific directory
  if [[ -d "$1" ]]; then
    rm -rf "$1"
    echo "Cleaned: $1"
  else
    echo "Directory not found: $1" >&2
    exit 1
  fi
else
  # Clean all video temp directories
  CLEANED=0
  for dir in /tmp/video-frames-* /tmp/video-download-*; do
    if [[ -d "$dir" ]]; then
      rm -rf "$dir"
      CLEANED=$((CLEANED + 1))
    fi
  done
  echo "Cleaned $CLEANED temporary video directories"
fi
