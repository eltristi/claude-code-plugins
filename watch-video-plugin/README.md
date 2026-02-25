# watch-video

Enable Claude Code to watch and analyze video files by extracting frames with FFMPEG and using multimodal image analysis.

## Features

- **Local videos**: Analyze `.mp4`, `.mov`, `.webm`, `.avi`, `.mkv` files
- **Remote videos**: Download and analyze from YouTube, Loom, Vimeo, or direct URLs
- **Smart extraction**: Adjusts frame density based on video duration (caps at 60 frames)
- **Multi-pass analysis**: Overview first, then detail on interesting segments for long videos
- **Context-aware**: Auto-triggers when video URLs appear in Asana tasks, Linear issues, or conversation
- **Auto-cleanup**: Temporary frames are cleaned up after analysis

## Prerequisites

**Required:**
```bash
brew install ffmpeg
```

**Optional (for YouTube/Loom/Vimeo URLs):**
```bash
brew install yt-dlp
```

## Installation

### From marketplace

```
/plugin marketplace add eltristi/claude-code-plugins
/plugin install watch-video
```

### Local development

```bash
claude --plugin-dir /path/to/watch-video-plugin
```

## Usage

### Slash command

```
/watch-video demo.mp4
/watch-video recording.mov what bugs do you see?
/watch-video https://www.loom.com/share/abc123
```

### Auto-triggering

The skill activates automatically when Claude encounters:
- A video file path in conversation
- A video URL (YouTube, Loom, Vimeo, direct links)
- Video attachments in Asana tasks or Linear issues

### Examples

**General summary:**
> "Watch this video and tell me what happens: ./demo.mp4"

**Bug analysis:**
> "There's a screen recording of the bug in this Asana task, can you check it?"

**Tutorial extraction:**
> "/watch-video tutorial.mp4 what are the setup steps?"

## Components

| Component | Purpose |
|-----------|---------|
| `skills/watch-video/` | Auto-triggering skill with FFMPEG workflow |
| `commands/watch-video.md` | `/watch-video` slash command |
| `agents/video-analyzer.md` | Autonomous analysis agent |
| `scripts/extract-frames.sh` | FFMPEG frame extraction wrapper |
| `scripts/download-video.sh` | Video downloader (curl + yt-dlp) |
| `scripts/cleanup-frames.sh` | Temp file cleanup utility |
