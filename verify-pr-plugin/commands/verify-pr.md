---
description: Verify a PR by generating e2e tests, recording videos, and posting results
argument-hint: [pr-number-or-url]
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
---

Verify the PR by running the verify-pr skill workflow end-to-end.

## Instructions

1. Parse the user's input:
   - **PR argument** (optional): A PR number or URL (first argument)
   - If no argument, auto-detect from current branch

2. Follow the verify-pr skill workflow in order:
   - Run pre-flight checks using `${CLAUDE_PLUGIN_ROOT}/skills/verify-pr/scripts/preflight.sh`
   - Verify Gyazo MCP availability
   - Gather PR context (diff, changed files, comments)
   - Check if app is running using `${CLAUDE_PLUGIN_ROOT}/skills/verify-pr/scripts/detect-running.sh`
   - Build and launch if needed
   - Check authentication requirements
   - Generate test flows
   - Validate flows against running app
   - Record flows
   - Upload videos to Gyazo MCP
   - Post PR comment

3. Print progress headers at each phase:
   ```
   [verify-pr] Phase N: Description...
   ```

4. If any pre-flight check fails, stop with a clear local message.

5. Only post to the PR when there are videos to show or when no testable UI changes were detected.

## Examples

- `/verify-pr` — Auto-detect PR from current branch, run full verification
- `/verify-pr 42` — Verify PR #42
- `/verify-pr https://github.com/org/repo/pull/42` — Verify by URL
