---
description: Watch and analyze a video file or URL by extracting frames with FFMPEG
argument-hint: <path-or-url> [question about the video]
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Task
---

Analyze the video provided by the user using the watch-video skill.

## Instructions

1. Parse the user's input to identify:
   - **Video source**: A file path or URL (first argument)
   - **Question** (optional): Any text after the path/URL — this is what to focus on

2. If no argument is provided, ask the user for a video path or URL.

3. Follow the watch-video skill workflow:
   - Verify ffmpeg is installed
   - If the source is a URL, download it first using `${CLAUDE_PLUGIN_ROOT}/skills/watch-video/scripts/download-video.sh`
   - Extract frames using `${CLAUDE_PLUGIN_ROOT}/skills/watch-video/scripts/extract-frames.sh`
   - Read and analyze the extracted frames
   - Provide analysis based on context (summary, answer to question, or bug report)
   - Clean up temporary files when done

4. If the user asked a specific question, focus the analysis on answering that question.
   If no question was asked, provide a general chronological summary.

## Examples

- `/watch-video demo.mp4` — General summary of the video
- `/watch-video recording.mov what bugs do you see?` — Targeted bug analysis
- `/watch-video https://www.loom.com/share/abc123` — Analyze a Loom recording
- `/watch-video ./test-run.webm did all tests pass?` — Check test results in recording
