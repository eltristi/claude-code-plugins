---
description: "Run automated PR review-fix loop: reviews PR, fixes P1/P2 issues, re-reviews until clean (max 10 cycles)"
argument-hint: "[PR number, GitHub URL, branch name, or 'all' to include P3 fixes]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "Skill"]
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

**Check completion condition:**
- If NO P1 or P2 issues found → go to "Loop Complete"
- If fix scope includes P3 and NO issues at all → go to "Loop Complete"
- Otherwise → continue to Step 3

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

Go back to "Loop Start" to run the next review cycle.

### Loop Complete

Present the final summary:

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

### Next Steps:
1. Review the applied fixes (changes are unstaged)
2. Consider the P3 suggestions above
3. Run your test suite to verify nothing broke
4. Stage and commit when satisfied
```

### Cycle Limit Reached

If cycle counter exceeds 10:

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

### Recommended Actions:
1. Review the remaining issues manually
2. Check if any fixes are fighting each other
3. Consider whether remaining findings are false positives
4. Stage and commit the fixes that were successfully applied
```

## Important Rules

1. **Never expand scope beyond the PR** — only fix code that is part of the PR diff
2. **Never stage or commit automatically** — leave all changes as unstaged modifications for user review
3. **Always report progress** between cycles so the user can follow along
4. **Respect the project's patterns** — fixes should match existing code style and conventions
5. **If a fix is uncertain, suggest instead of applying** — flag it for manual review
6. **Consult `references/loop-patterns.md`** in the review-fix-loop skill for detailed patterns on handling specific issue types
