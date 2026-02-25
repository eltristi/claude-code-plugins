# Review-Fix Loop Patterns

Detailed patterns and strategies for handling common scenarios during the automated review-fix cycle.

## Fix Patterns by Issue Type

### Security Vulnerabilities (P1)

**SQL Injection:**
- Identify raw query construction
- Replace with parameterized queries or ORM methods
- Verify all user inputs are sanitized at the boundary

**XSS (Cross-Site Scripting):**
- Find unescaped output in templates
- Apply framework-appropriate escaping (e.g., `h()` in Rails, JSX auto-escaping in React)
- Check for usage of raw HTML rendering and replace with safe alternatives

**Path Traversal:**
- Validate file paths against allowed directories
- Use `File.expand_path` / `path.resolve` and verify prefix
- Reject paths containing `..`

**Authentication/Authorization:**
- Verify auth checks exist on all endpoints
- Ensure authorization scopes match the action
- Check for missing CSRF protection

### Performance Issues (P2)

**N+1 Queries:**
- Identify eager loading opportunities
- Add `includes` / `preload` / `eager_load` (Rails) or equivalent
- Verify the fix with query logging

**Missing Indexes:**
- Check columns used in WHERE, JOIN, ORDER BY
- Add appropriate database indexes
- Consider composite indexes for multi-column queries

**Unbounded Queries:**
- Add pagination or LIMIT clauses
- Implement cursor-based pagination for large datasets
- Add timeouts for long-running queries

### Architecture Concerns (P2)

**God Objects / Fat Controllers:**
- Extract service objects or concerns
- Move business logic out of controllers
- Keep changes scoped to PR files only

**Missing Error Handling:**
- Add appropriate rescue/catch blocks
- Ensure errors are logged with context
- Return meaningful error responses

**Tight Coupling:**
- Introduce interfaces or dependency injection
- Extract shared logic into modules
- Only refactor within PR scope

### Code Quality (P2)

**Duplication:**
- Extract shared logic into private methods
- Use modules/mixins for cross-class sharing
- Keep DRY changes within the PR's files

**Naming Issues:**
- Rename variables/methods for clarity
- Follow project naming conventions from CLAUDE.md
- Update all references within changed files

## Regression Prevention

### Common Fix Regressions

Fixes that commonly introduce new issues:

1. **Eager loading fixes** can change query ordering — verify sort expectations
2. **Input validation additions** can reject previously valid inputs — check edge cases
3. **Error handling additions** can swallow exceptions — ensure proper re-raising
4. **Refactoring extractions** can change method visibility — verify callers
5. **Security fixes** can break functionality — test the happy path still works

### Mitigation Strategies

- Read surrounding code before applying fixes
- Check for tests that cover the changed behavior
- Verify the fix matches the project's existing patterns
- Keep fixes minimal — change only what is necessary

## Scope Management

### In-Scope (Fix)

- Files modified in the PR diff
- Issues directly introduced by the PR's changes
- Security vulnerabilities in new code
- Performance regressions from new code

### Out-of-Scope (Suggest Only)

- Pre-existing issues in files not touched by the PR
- Architectural problems that require cross-cutting changes
- Issues that need new dependencies or infrastructure changes
- Problems that require domain knowledge to resolve safely

### Borderline Cases

When an issue spans both new and existing code:
- Fix the part in new code
- Suggest the fix for existing code
- Note the dependency in the suggestion

## Cycle Escalation

### Cycle 1-3: Normal Operation
Standard fix-and-verify cycle. Most PRs resolve within 3 cycles.

### Cycle 4-6: Investigate Patterns
If issues persist, look for:
- Fixes fighting each other (fix A breaks fix B)
- Underlying design problem causing surface-level symptoms
- Agents flagging style preferences rather than real issues

Strategy: Group related issues and fix them together in one pass.

### Cycle 7-10: Diminishing Returns
If still looping:
- Flag remaining issues as requiring manual intervention
- Check if agents disagree on approach
- Consider that some findings may be false positives at lower confidence
- Present remaining issues to user for decision

## P3 Handling

### Default Behavior (Suggest Only)

Present P3 issues as a list after the loop completes:
```
### Remaining P3 Suggestions:
- [ ] Consider renaming `processData` to `transformUserInput` for clarity (src/utils.ts:45)
- [ ] Documentation for `handleAuth` could be more detailed (src/auth.ts:12)
```

### When User Requests "Fix All"

Detect user intent from phrases like:
- "fix all issues"
- "fix everything"
- "including P3"
- "fix all findings"
- "address all suggestions"

When detected, include P3 issues in the fix phase alongside P1 and P2.
