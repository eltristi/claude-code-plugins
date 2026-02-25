---
description: "Run automated PR review-fix loop: reviews PR, fixes P1/P2 issues, re-reviews until clean (max 10 cycles)"
argument-hint: "[PR number, GitHub URL, branch name, or 'all' to include P3 fixes]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "Skill", "AskUserQuestion"]
model: "opus"
---

# PR Review-Fix Loop

<command_purpose>Automated review-fix cycle that reviews a PR using multi-agent analysis, fixes discovered issues, and re-reviews until no P1/P2 issues remain or 10 cycles are reached.</command_purpose>

## Parse Arguments

<review_target>$ARGUMENTS</review_target>

Determine from the arguments:
1. **Target**: PR number, GitHub URL, branch name, or empty (current branch)
2. **Fix scope**: If arguments contain "all", "everything", or "including p3" → fix P3 issues too. Otherwise → fix P1/P2 only, suggest P3.

## Prerequisites

- Git repository with GitHub CLI (`gh`) installed and authenticated
- `compound-engineering` plugin installed (provides `workflows:review`)
- Current branch should be the PR branch or able to check it out

## Execution

### Initialize

```
Cycle: 0
Max cycles: 10
Fix scope: P1+P2 (or P1+P2+P3 if "all" requested)
Status: STARTING
Fixed issues log: []
```

### Loop Start

Increment cycle counter. If cycle > 10, go to "Cycle Limit Reached".

Report to user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Review-Fix Loop — Cycle {N}/10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 1: Run Review

Invoke the compound-engineering review workflow:

```
Invoke skill: compound-engineering:workflows:review <target>
```

This runs all configured review agents from the project's `compound-engineering.local.md`, including conditional agents for migrations, schema changes, etc.

Wait for the review to complete and collect all findings.

### Step 2: Categorize Findings

Parse the review output and categorize:

- **P1 Critical** (🔴): Security vulnerabilities, data corruption, breaking changes
- **P2 Important** (🟡): Performance, architecture, significant quality issues
- **P3 Nice-to-Have** (🔵): Minor improvements, cleanup, docs

**Check completion condition (STRICT — do not skip this check):**
- If ANY P1 or P2 issues exist → you MUST continue to Step 3. Do NOT present next steps or summaries.
- If NO P1 or P2 issues found (only P3 or nothing) → go to "Loop Complete"
- If fix scope includes P3 and NO issues at all → go to "Loop Complete"

### Step 3: Fix Issues

For each issue that matches the fix scope (P1+P2 always, P3 only if "all" mode):

1. Read the affected file at the reported location
2. Understand the surrounding context — read enough lines to grasp the intent
3. Apply the fix using Edit tool with minimal, targeted changes
4. **Scope constraint**: Only modify files in the PR diff. If a fix requires changes outside PR scope, log it as a suggestion and skip.
5. Log the fix: `{cycle}-{severity}-{description}-{file:line}`

After all fixes are applied:
- Do NOT stage or commit — leave changes as unstaged modifications for user review
- Report what was fixed:

```
Cycle {N} fixes applied:
  ✓ P1: Fixed path traversal in src/api/upload.ts:45
  ✓ P2: Added eager loading to prevent N+1 in app/models/user.rb:23
  ✓ P2: Added input validation for email param in src/auth.ts:67
  ⊘ P2: Architecture issue requires changes outside PR scope (suggested)
```

### Step 4: Re-Review Decision

**CRITICAL: If any P1 or P2 issues were fixed in this cycle, you MUST go back to "Loop Start" to re-review. Do NOT present "Next Steps", completion summaries, or any final output. Do NOT pause or ask the user. Continue the loop immediately.**

Go back to "Loop Start" to run the next review cycle.

### Loop Complete

Present the summary (without "Next Steps") and then ask the user what they'd like to do:

```markdown
## ✅ Review-Fix Loop Complete

**Cycles:** {N} of 10
**Status:** CLEAN — No P1/P2 issues remaining

### Fixed Issues (all cycles):
{For each fixed issue across all cycles:}
- ✓ [P{severity}] {description} ({file}:{line}) — cycle {N}

### Remaining P3 Suggestions:
{If any P3 issues were not fixed:}
- ○ {description} ({file}:{line})

### Files Modified:
{List each file changed with a one-line summary}
```

**After presenting the summary, ask the user using AskUserQuestion:**

Prompt: "All P1/P2 issues are resolved. What would you like to do next?"

Suggestions (provide all that apply):
- "Review the diff of all applied fixes" (always)
- "Fix P3 suggestions too" (if there are remaining P3 issues)
- "Run tests to verify nothing broke" (always)
- "Commit the fixes" (always)
- "Discard changes — I'll handle it manually" (always)

Wait for the user's response and act on it before doing anything else. Do NOT proceed autonomously.

### Cycle Limit Reached

If cycle counter exceeds 10, present the summary and ask the user:

```markdown
## ⚠️ Review-Fix Loop — Cycle Limit Reached

**Cycles:** 10 of 10
**Status:** LIMIT REACHED — Some issues may remain

### Fixed Issues (all cycles):
{List all fixed issues}

### Remaining Unresolved Issues:
{List issues still present after 10 cycles}
- ⚠ [P{severity}] {description} ({file}:{line}) — persisted through {N} fix attempts

### Why This Happened:
Possible reasons:
- Fixes are conflicting with each other
- Underlying design issue causing recurring surface symptoms
- Some findings may need manual intervention
```

**After presenting the summary, ask the user using AskUserQuestion:**

Prompt: "Cycle limit reached with issues remaining. How would you like to proceed?"

Suggestions:
- "Review the diff of all applied fixes" (always)
- "Show me the remaining issues in detail so I can fix manually" (always)
- "Run tests to verify the fixes so far" (always)
- "Commit the fixes applied so far" (always)
- "Discard all changes" (always)

Wait for the user's response and act on it before doing anything else. Do NOT proceed autonomously.

## Important Rules

1. **Never expand scope beyond the PR** — only fix code that is part of the PR diff
2. **Never stage or commit automatically** — leave all changes as unstaged modifications for user review
3. **Always report progress** between cycles so the user can follow along
4. **Respect the project's patterns** — fixes should match existing code style and conventions
5. **If a fix is uncertain, suggest instead of applying** — flag it for manual review
6. **Consult `references/loop-patterns.md`** in the review-fix-loop skill for detailed patterns on handling specific issue types
7. **NEVER present "Next Steps", final summaries, or completion output while P1/P2 issues remain** — the loop must continue automatically until only P3 issues (or nothing) remain. Do not pause, ask for confirmation, or suggest the user review intermediate results. The only time "Next Steps" should appear is in the final "Loop Complete" or "Cycle Limit Reached" output.
