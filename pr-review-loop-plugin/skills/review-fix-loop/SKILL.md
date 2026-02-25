---
name: review-fix-loop
description: This skill should be used when the user asks to "review and fix my PR", "auto-fix PR issues", "review loop", "fix PR until clean", "review-fix-loop", "iterative PR review", "clean up my PR", "review my PR and fix the issues", or wants an automated cycle of reviewing a pull request and fixing discovered issues until no P1/P2 issues remain.
version: 1.0.0
---

# PR Review-Fix Loop

Automated PR review pipeline that runs multi-agent code review, fixes discovered issues, and re-reviews in a loop until the PR is clean or the cycle limit is reached.

## Overview

This skill orchestrates a review-fix cycle:

1. Run `compound-engineering:workflows:review` on the PR
2. Parse findings by severity (P1 Critical, P2 Important, P3 Nice-to-Have)
3. Fix all P1 and P2 issues directly in the codebase
4. Suggest P3 issues without fixing (unless the user explicitly requests fixing all issues)
5. Re-run the review to verify fixes and catch regressions
6. Repeat until no P1/P2 issues remain, or max **10 cycles** reached

## Workflow

### Phase 1: Initial Review

Invoke the compound-engineering review workflow on the target PR. This delegates fully to `workflows:review`, which:
- Reads project-specific review agents from `compound-engineering.local.md`
- Launches all configured agents in parallel (security, performance, architecture, etc.)
- Runs conditional agents for migrations, schema changes, etc.
- Performs ultra-thinking deep analysis
- Produces categorized findings with severity levels

```
Invoke skill: compound-engineering:workflows:review <target>
```

Where `<target>` is the PR number, GitHub URL, branch name, or `latest`.

### Phase 2: Parse and Categorize Findings

After the review completes, categorize all findings:

| Severity | Action | Label |
|----------|--------|-------|
| P1 Critical | **Fix immediately** | Blocks merge, security/data issues |
| P2 Important | **Fix immediately** | Performance, architecture, quality |
| P3 Nice-to-Have | **Suggest only** | Enhancements, cleanup, docs |

**Exception:** If the user has explicitly requested to fix "all issues", "everything", or "including P3", then P3 issues are also fixed.

### Phase 3: Fix Issues

For each P1 and P2 finding:

1. Read the affected file(s) at the reported location
2. Understand the issue in context — do not blindly apply fixes
3. Implement the fix with minimal changes scoped to the PR's own code
4. Verify the fix does not introduce new issues or break existing functionality

**Scope constraint:** Only modify files that are part of the PR diff. Do not expand scope to fix pre-existing issues in untouched files. If a fix requires changes outside the PR scope, flag it as a suggestion instead.

**Fix strategy:**
- Security vulnerabilities → apply the secure pattern
- Performance issues → optimize the specific code path
- Architecture concerns → refactor within PR scope only
- Code quality → clean up the flagged code
- Bug fixes → correct the logic error

After fixing, do NOT stage or commit — leave changes as unstaged modifications for user review.

### Phase 4: Re-Review

Run the review workflow again on the same target to verify:
- All previously reported P1/P2 issues are resolved
- No new P1/P2 issues were introduced by the fixes
- Remaining findings are only P3 suggestions (or new P1/P2 to fix)

### Phase 5: Loop or Complete

**CRITICAL: Do NOT present the final summary, "Next Steps", or any completion message while P1 or P2 issues remain. The loop MUST continue until all P1/P2 issues are resolved.**

**If new P1/P2 issues are found:** Return to Phase 3 and fix them immediately. Increment the cycle counter. Do not pause, summarize, or ask the user — just continue fixing.

**If only P3 issues remain (or no issues):** ONLY THEN is the loop complete. Present the final summary.

**If cycle limit (10) is reached:** Stop the loop. Present all remaining issues with a warning that the cycle limit was hit.

### Cycle Tracking

Maintain a cycle counter throughout the process:

```
Cycle 1: Initial review → found 3 P1, 5 P2, 2 P3 → fixing 8 issues
Cycle 2: Re-review → found 1 P2 (new from fix) → fixing 1 issue
Cycle 3: Re-review → found 0 P1/P2 → CLEAN ✓
```

Report cycle progress to the user between each iteration.

## Final Summary & User Prompt

After the loop completes, present the summary **without a "Next Steps" section**. Instead, use `AskUserQuestion` to let the user decide what to do:

```markdown
## Review-Fix Loop Complete

**Cycles:** X of 10 max
**Status:** CLEAN / CYCLE LIMIT REACHED

### Fixed Issues (across all cycles):
- [X] P1: <description> (file:line) — fixed in cycle N
- [X] P2: <description> (file:line) — fixed in cycle N

### Remaining P3 Suggestions:
- [ ] P3: <description> (file:line)

### Changes Made:
- <file1>: <summary of changes>
- <file2>: <summary of changes>
```

Then ask the user with contextual options like:
- "Run one more review cycle to double-check"
- "Review the diff of all applied fixes"
- "Fix P3 suggestions too" (if P3 issues remain)
- "Run tests to verify nothing broke"
- "Commit the fixes"
- "Discard changes"

**Do NOT autonomously proceed after the summary. Wait for the user's choice.**

## Configuration

This skill delegates entirely to `compound-engineering:workflows:review` for the review phase. All review agent configuration comes from the project's `compound-engineering.local.md` file.

No additional configuration is needed for this skill.

## Critical Loop Discipline

**NEVER do any of the following while P1 or P2 issues are still unresolved:**
- Present "Next Steps" or completion summaries
- Ask the user to review changes or consider suggestions
- Suggest running tests or committing
- Pause the loop to report intermediate state as if it were final
- Output the "Review-Fix Loop Complete" template

The ONLY acceptable outputs between cycles are the cycle progress line (e.g., `Cycle 2: Re-review → found 1 P2 → fixing 1 issue`). Everything else waits until the loop terminates.

## Edge Cases

- **No issues found on first review:** Report the PR is clean — no loop needed.
- **Fix introduces more issues than it resolves:** Continue the loop; the cycle limit prevents infinite regression.
- **Issue cannot be fixed automatically:** Flag it as requiring manual intervention and exclude from re-review expectations.
- **Files outside PR scope flagged:** Suggest only; do not modify files not in the PR diff.

## Additional Resources

### Reference Files

- **`references/loop-patterns.md`** — Detailed patterns for handling common fix scenarios and edge cases during the review-fix cycle.
