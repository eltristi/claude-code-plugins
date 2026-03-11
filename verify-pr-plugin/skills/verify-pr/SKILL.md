---
name: verify-pr
description: "This skill should be used when the user asks to verify a PR, test a PR, verify my pull request, check if my PR works, record a video of my PR changes, run e2e tests on my PR, visually verify my PR, generate test videos for this PR, post verification results, or runs /verify-pr. It automates PR verification by gathering PR context, building/launching the app, generating e2e test flows from the PR changes, recording video proof, uploading to Gyazo, and posting results as a PR comment. Supports Expo (mobile, Maestro) and Laravel (Docker web, Playwright) projects."
---

# Verify PR

Automate PR verification by generating e2e test flows from PR context, recording them on video, and posting visual proof to the PR comment.

## Supported Project Types

| Type | Detection | Test Tool | Platforms |
|------|-----------|-----------|-----------|
| **Expo** | `app.json` with `expo` key | Maestro | iOS Simulator + Android Emulator (sequential) |
| **Laravel** | `artisan` + `composer.json` + `docker-compose.yml` | Playwright | Browser (web) |

## Workflow

### Pre-flight Checks

Run the pre-flight script to validate all prerequisites:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/verify-pr/scripts/preflight.sh" [pr-number-or-url]
```

The script checks: `gh` CLI, PR existence, project type, testing tools, branch sync, and platform availability. All failures print to terminal only — never post local environment issues to the PR.

After the script passes, verify Gyazo MCP is available by checking MCP tool availability. If not configured, stop with:
> "Gyazo MCP is not configured. Install and configure the Gyazo MCP server before running /verify-pr."

### Phase 1: Gather PR Context

Fetch all PR information:

```bash
gh pr view <number> --json title,body,number,url,headRefOid
gh pr diff <number>
gh pr diff <number> --name-only
gh pr view <number> --json comments
```

Read the full source of each changed file (not just the diff) to understand context.

**PR size check:** If the PR touches more than 15 files or spans multiple unrelated features, ask the user:
> "This PR is large with many changes. To provide meaningful verification, specify which changes to focus on, or consider splitting the PR."

### Phase 2: Build & Launch

Run the detection script first:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/verify-pr/scripts/detect-running.sh" <project-type>
```

If the app is already running, skip to Phase 3.

#### Launch Expo

1. Start Metro: `npx expo start` (run in background)
2. Check available platforms from pre-flight results:
   - iOS available → `npx expo run:ios`
   - Android available → `npx expo run:android`
   - Skip unavailable platforms with warning (do not fail)
3. Discover bundle ID from `app.json`:
   - iOS: `expo.ios.bundleIdentifier`
   - Android: `expo.android.package`
   - Expo Go fallback: `host.exp.Exponent`
4. Wait for app to load — timeout: 10 minutes for build, 60 seconds for health check

#### Launch Laravel (Docker)

1. If non-project containers occupy conflicting ports (80, 443, 8080, 3306, 5432):
   - Identify: `docker ps --format '{{.Names}} {{.Ports}}'`
   - Stop non-project containers on conflicting ports
   - Log what was stopped to terminal
2. Start: `docker compose up -d`
3. Setup inside container if needed:
   - `docker compose exec app composer install` (if `vendor/` missing)
   - `docker compose exec app php artisan migrate --force`
   - `docker compose exec app npm run dev` (if frontend build exists)
4. Discover app URL from compose config — parse exposed ports
5. Wait for health check — timeout: 5 min build, 3 min deps, 60s health

### Phase 3: Authentication Handling

Analyze the PR diff to determine if changed routes/screens require authentication.

**Expo:** Check if changed components are behind navigation guards, auth context, or protected routes.

**Laravel:** Check if changed routes use `auth` middleware, or views are in authenticated layouts.

If auth is needed:
1. Ask the user for test credentials:
   > "The PR changes touch authenticated areas. Provide test credentials (email and password) to generate login flows."
2. Store credentials in memory for this run only — never write to disk
3. Generate a login flow as the first step of test scenarios needing auth

### Phase 4: Generate Test Flows

Analyze the PR to identify user-facing behavior changes and generate test files to `/tmp/pr-verify-flows/`.

#### Analysis

From the diff, title, description, and comments, identify:
- New screens or pages added
- Existing flows modified (forms, buttons, navigation)
- Visual changes (styling, layout)
- Backend changes affecting UI

#### Generate Flows

**Expo (Maestro YAML):** Consult `references/maestro-patterns.md` for syntax.
- File naming: `pr-<number>-<scenario-name>.yaml`
- Use `launchApp` with discovered bundle ID
- Include login steps if auth needed

**Laravel (Playwright):** Consult `references/playwright-patterns.md` for syntax.
- File naming: `pr-<number>-<scenario-name>.spec.ts`
- Also generate `playwright.config.ts` with `video: 'on'`
- Use discovered app URL as base
- Include login steps if auth needed

#### Validate Against Running App

Before recording, validate each flow:
1. Take a screenshot (iOS Simulator MCP / Playwright snapshot / Chrome DevTools MCP)
2. Compare expected UI elements against actual screen
3. Adjust selectors if mismatch — max 3 attempts per flow
4. If still failing after 3 attempts, skip flow with warning

### Phase 5: Record

**Expo:**
```bash
maestro record <flow.yaml> --output /tmp/pr-verify-flows/<flow-name>-ios.mp4
maestro record <flow.yaml> --output /tmp/pr-verify-flows/<flow-name>-android.mp4
```
iOS first, then Android. Per-flow timeout: 3 minutes.

**Laravel:**
Run Playwright with video recording enabled. Videos saved to test-results directory.
Per-flow timeout: 3 minutes.

If an individual flow fails, capture the error and continue with remaining flows.

### Phase 6: Upload & Post

#### Upload to Gyazo

Use Gyazo MCP to upload each video. Collect returned URLs.

If Gyazo upload fails: print local file paths to terminal, **do not post PR comment**. No video = no comment.

#### Post PR Comment

Consult `references/pr-comment-template.md` for the comment format.

**Idempotency:** On re-runs, find and update the existing verification comment instead of creating a new one:
```bash
# Find existing comment ID via gh api
COMMENT_ID=$(gh api repos/{owner}/{repo}/issues/<number>/comments --jq '.[] | select(.body | startswith("## PR Verification")) | .id')

# Update if found
if [ -n "$COMMENT_ID" ]; then
  gh api repos/{owner}/{repo}/issues/comments/$COMMENT_ID -X PATCH -f body="<new-body>"
else
  gh pr comment <number> --body "<new-body>"
fi
```

**Post to PR when:**
- Test results with videos (pass or fail)
- "No testable UI changes detected"

**Local only (never post):**
- Environment/tooling issues
- Build/Docker failures
- Gyazo upload failures

## Progress Output

Print phase headers to terminal throughout:
```
[verify-pr] Pre-flight: Checking prerequisites...
[verify-pr] Phase 1: Gathering PR context...
[verify-pr] Phase 2: Building and launching app...
[verify-pr] Phase 3: Checking authentication requirements...
[verify-pr] Phase 4: Generating test flows (N scenarios)...
[verify-pr] Phase 5: Recording flows...
[verify-pr] Phase 6: Uploading videos and posting PR comment...
[verify-pr] Done! PR comment posted: <url>
```

## Error Handling

| Phase | Failure | Action |
|-------|---------|--------|
| Pre-flight | Any check fails | Local message, stop |
| Build/Docker | Build fails | Local message, stop |
| App launch | Timeout | Local message, stop |
| PR too large | Many unrelated changes | Ask user what to test |
| Auth needed | No credentials | Ask user for credentials |
| Flow generation | No testable behavior | PR comment: no testable UI changes |
| Flow validation | Selector mismatch | Retry 3x, then run as-is |
| Recording | Individual flow fails | Capture error, continue |
| Recording | All flows fail | PR comment with failure details |
| Upload | Gyazo MCP fails | Local message with file paths, stop |

## Cleanup

- Video files and flows kept in `/tmp/pr-verify-flows/`
- Docker containers started by the skill are left running
- No automatic cleanup — OS handles `/tmp` lifecycle
