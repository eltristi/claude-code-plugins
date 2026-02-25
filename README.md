# Claude Code Plugins

A collection of plugins for [Claude Code](https://claude.com/claude-code) that provide specialized skills and commands for common development tasks.

## Available Plugins

### write-api-docs

Generate Swagger/OpenAPI documentation for Laravel APIs using `zircote/swagger-php` with PHP 8 Attributes.

**Features:**
- Analyzes `routes/api.php` to identify all API endpoints
- Creates documentation in separate `app/Docs/` files (not inline with controllers)
- Ensures every endpoint has an `operationId` for orval/TypeScript client generation
- Generates JSON and YAML specs with zero warnings
- Provides reusable schemas for models, requests, and responses

**Use when:**
- Creating or updating API endpoint documentation
- Setting up Swagger docs for a new Laravel project
- Generating TypeScript clients with orval

### watch-video

Watch and analyze video files by extracting frames with FFMPEG and using Claude's multimodal image analysis.

**Features:**
- Analyzes local video files (`.mp4`, `.mov`, `.webm`, `.avi`, `.mkv`)
- Downloads and analyzes remote videos (YouTube, Loom, Vimeo, direct URLs)
- Smart frame extraction with adjustable density (default: 1 fps, max 60 frames)
- Multi-pass analysis for long videos (overview first, then detail on key segments)
- Auto-triggers when video URLs appear in Asana tasks, Linear issues, or conversation
- Scene detection for presentations and demos with irregular content changes

**Use when:**
- Analyzing screen recordings or bug reproduction videos
- Reviewing UI/UX walkthrough recordings
- Summarizing tutorial or presentation videos
- Any task context that includes video attachments

## Installation

### 1. Add the marketplace

```
/plugin marketplace add eltristi/claude-plugins
```

### 2. Install a plugin

```
/plugin install write-api-docs
```

## Usage

After installing a plugin, you can use its skill or slash command:

**Slash command:**
```
/write-api-docs
```

**Or let Claude detect when to use the skill automatically** - Claude will recognize when you're working on API documentation tasks and apply the skill's best practices.

## Requirements

For the `write-api-docs` plugin:
- Laravel project with `zircote/swagger-php` installed
- PHP 8.0+ (for Attributes support)
- `swagger-cli` for YAML conversion (`npx swagger-cli`)

For the `watch-video` plugin:
- `ffmpeg` + `ffprobe` (`brew install ffmpeg`)
- `yt-dlp` (optional, for YouTube/Loom/Vimeo: `brew install yt-dlp`)