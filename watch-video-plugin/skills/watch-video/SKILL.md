---
name: watch-video
description: >-
  This skill should be used when the user asks to "watch a video", "analyze a video",
  "describe this video", "play this video", "review a screen recording", "summarize
  this video", "what happens in this video", or provides a video file path or video URL.
  Also triggers when encountering video attachments or video links in Asana tasks,
  Linear issues, or any external context that contains video content (.mp4, .mov, .webm,
  .avi, .mkv, YouTube, Loom, Vimeo URLs). Enables Claude Code to understand video content
  through FFMPEG frame extraction and multimodal image analysis.
version: 1.0.0
---

# Watch Video

## Overview

Enable understanding of video content by extracting frames with FFMPEG and analyzing them
as images. This bridges the gap between Claude's multimodal image capabilities and temporal
video content.

## Prerequisites

Required tools (check before proceeding):
- **ffmpeg** + **ffprobe**: `brew install ffmpeg` or system package manager
- **yt-dlp** (optional, for YouTube/Loom/Vimeo): `brew install yt-dlp`

Verify availability by running `which ffmpeg ffprobe` before starting extraction.

## Core Workflow

### Step 1: Detect Video Source

Identify the video source type from user input or context:

| Source Type | Detection Pattern | Action |
|-------------|-------------------|--------|
| Local file | Path ending in `.mp4`, `.mov`, `.webm`, `.avi`, `.mkv` | Use directly |
| Direct URL | URL ending in video extension | Download with `scripts/download-video.sh` |
| YouTube/Loom/Vimeo | URL containing platform domain | Download with `scripts/download-video.sh` (requires yt-dlp) |
| Asana/Linear attachment | Video URL within task/issue content | Extract URL, download with `scripts/download-video.sh` |

When reading Asana tasks or Linear issues, scan all attachments and body content for
video URLs. If a video is found and relevant to the task context, proactively offer to
analyze it.

### Step 2: Extract Frames

Run the extraction script located at `${CLAUDE_PLUGIN_ROOT}/skills/watch-video/scripts/extract-frames.sh`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/watch-video/scripts/extract-frames.sh" <video_path> [fps] [max_frames]
```

**Default parameters:**
- `fps`: 1 (one frame per second)
- `max_frames`: 60

The script outputs JSON metadata including `output_dir`, `frame_count`, `duration_seconds`,
and `timestamp_file`.

**Adjusting extraction density:**

| Video Duration | Recommended Strategy |
|----------------|---------------------|
| < 30 seconds | 2 fps, max 60 frames (capture detail) |
| 30s - 5 min | 1 fps, max 60 frames (default) |
| 5 - 30 min | 0.2 fps (1 per 5s), max 60 frames |
| 30+ min | 0.1 fps (1 per 10s), max 60 frames (overview first) |

### Step 3: Analyze Frames

Use the Read tool to view extracted frame images. The Read tool supports reading image
files — each frame becomes a visual input for analysis.

**Single-pass analysis** (short videos, < 2 min):
1. Read all frames sequentially
2. Note the timestamp from `timestamps.txt` for each frame
3. Build a coherent understanding of the video content

**Multi-pass analysis** (longer videos):
1. **Overview pass**: Read every 5th-10th frame for a broad summary
2. **Identify segments of interest**: Note timestamps where content changes significantly
3. **Detail pass**: Re-extract at higher density for interesting segments using a targeted
   time range with ffmpeg directly:
   ```bash
   ffmpeg -ss <start_time> -to <end_time> -i <video> -vf "fps=2" <output_dir>/detail_%05d.jpg
   ```
4. Read the detail frames for deeper analysis

### Step 4: Synthesize and Respond

Adapt the output format to context:

- **General summary**: Describe what happens in the video chronologically
- **Targeted question**: Focus analysis on answering the specific question
- **Bug report / screen recording**: Note UI states, error messages, unexpected behavior with timestamps
- **Tutorial / walkthrough**: Extract key steps and instructions shown

Always include timestamps when referencing specific moments (e.g., "At 0:45, the modal appears").

### Step 5: Clean Up

After analysis is complete, clean up temporary files:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/watch-video/scripts/cleanup-frames.sh" <output_dir>
```

Also clean up any downloaded video files from `scripts/download-video.sh`.

## Scene Detection (Advanced)

For videos where content changes are irregular (presentations, demos), use FFMPEG scene
detection instead of fixed FPS:

```bash
ffmpeg -i <video> -vf "select='gt(scene,0.3)',showinfo" -vsync vfr <output_dir>/scene_%05d.jpg
```

Adjust the threshold (0.3) — lower values capture more scene changes, higher values
capture only major transitions. Use this when:
- Video has long static periods (presentations, code demos)
- Content changes are bursty (UI walkthroughs with pauses)

## Video URL Patterns

### Recognized patterns to trigger this skill:

**File extensions**: `.mp4`, `.mov`, `.webm`, `.avi`, `.mkv`, `.m4v`, `.flv`

**Platform URLs**:
- YouTube: `youtube.com/watch?v=`, `youtu.be/`
- Loom: `loom.com/share/`
- Vimeo: `vimeo.com/`

**Attachment URLs** (from project management tools):
- Asana: attachment URLs from `asana_get_attachment` or `asana_get_attachments_for_object`
- Linear: attachment URLs from issue content
- Any direct URL serving video content-type

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| `ffmpeg not installed` | Missing dependency | Prompt user: `brew install ffmpeg` |
| `yt-dlp not installed` | Trying streaming URL without yt-dlp | Prompt user: `brew install yt-dlp` |
| `Could not determine duration` | Corrupted or unsupported file | Ask user to verify file or provide alternate format |
| `Downloaded file is not valid video` | URL doesn't serve video content | Ask user for direct video URL |

## Additional Resources

### Reference Files

For detailed guidance, consult:
- **`references/frame-analysis-patterns.md`** — Patterns for analyzing different video types (screen recordings, presentations, real-world footage)

### Utility Scripts

- **`scripts/extract-frames.sh`** — Core frame extraction (FFMPEG wrapper with smart FPS adjustment)
- **`scripts/download-video.sh`** — Download videos from URLs (supports YouTube, Loom, direct links)
- **`scripts/cleanup-frames.sh`** — Clean up temporary frame directories
