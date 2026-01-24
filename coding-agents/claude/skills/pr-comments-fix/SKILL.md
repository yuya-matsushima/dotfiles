---
name: pr-comments-fix
description: Collect and categorize PR review comments, then address them sequentially
argument-hint: [<pr-number>]
---

# PR Comments Fix Command

Automatically collect and categorize PR review comments, then address each one with commits.

## Instructions

### 1. Parse Arguments and Get PR Number

**Determine PR number**:
- If PR number is specified in `$ARGUMENTS`: use that number
- If not specified: auto-detect from current branch using `gh pr view --json number -q '.number'`
- If no PR found: display error message and exit

### 2. Collect Review Comments

Fetch comments using these commands:

```bash
# PR basic info and review info
gh pr view <PR> --json reviews,comments,latestReviews,reviewDecision

# Inline comments (with file and line number)
gh api repos/{owner}/{repo}/pulls/<PR>/comments
```

### 3. Categorize Comments

Categorize by **type of issue** pointed out:

| Priority | Category | Examples |
|----------|----------|----------|
| 1 | Security | Vulnerabilities, auth issues, sensitive data exposure, input validation flaws |
| 2 | Bug / Logic Error | Runtime errors, boundary condition misses, unhandled null/undefined, race conditions |
| 3 | Performance | N+1 queries, unnecessary loops, memory leaks, inefficient algorithms |
| 4 | Maintainability / Design | Separation of concerns, duplicate code, naming improvements, type definitions |
| 5 | Code Style | Formatting, lint issues, comment additions, import order |
| - | Question / Clarification | Implementation intent, spec questions (no code change needed, reply only) |
| - | No Action Required | LGTM, +1, approval comments |

**Classification criteria**:
- Judge by the **impact** of the issue pointed out
- Keywords in text ("must", "should", etc.) are secondary reference
- If multiple categories apply, use the higher priority

### 4. Filtering

Exclude the following comments:
- **Resolved**: Threads with `isResolved: true`
- **Own comments**: Matching username from `gh api user`
- **No Action Required category**: LGTM, +1, approval comments, etc.

### 5. Display Summary

Show categorized results:

```
## PR #<number> Review Comments

### Priority 1: Security (X items)
- [ ] auth.ts:42 - "Input sanitization needed" (@reviewer)

### Priority 2: Bug / Logic Error (X items)
- [ ] handler.ts:78 - "Missing null check" (@reviewer)

### Priority 3: Performance (X items)
- [ ] query.ts:100 - "This is an N+1 query" (@reviewer)

### Priority 4: Maintainability / Design (X items)
- [ ] service.ts:55 - "This should be extracted to a separate class" (@reviewer)

### Priority 5: Code Style (X items)
- [ ] utils.ts:20 - "Please clarify variable name" (@reviewer)

### Question / Clarification (X items)
- [ ] config.ts:30 - "What's the intent of this setting?" (@reviewer)

---
To address: X items / Total: Y items (Excluded: Z items)
```

### 6. Address Sequentially (Auto-execute)

**Always auto-execute mode**: Start addressing without confirmation

Address each comment in order: Priority 1 → 2 → 3 → 4 → 5 → Questions

**When code changes are needed** (Priority 1-5):
1. Read the target file
2. Modify code according to comment
3. Stage changes: `git add <file>`
4. Run `/commit --auto` (commits using Conventional Commits rules)

**When reply is needed** (Question / Clarification category):
1. Review code and answer the question
2. Reply via PR comment:
   ```bash
   gh pr comment <PR> --body "<reply content>"
   ```

### 7. Final Summary

After all items are addressed, display summary:

```
## Completed

- Code fixes: X items
- Commits created: Y items
- Questions replied: Z items

### Created commits:
- abc1234: fix: resolve null check issue
- def5678: perf: optimize database query
```

### 8. Auto Push

If there are changes, push to remote:

```bash
git push origin HEAD
```

## Examples

```bash
# Address comments on current branch's PR
/pr-comments-fix

# Specify PR number
/pr-comments-fix 123
```

## Notes

- **Auto-execute**: All actions are executed without confirmation
- **Commit granularity**: Each comment is addressed with an individual commit
- **Reply format**: Replies to questions should be concise and technically accurate
- **When unable to address**: Post a comment explaining why technical resolution is difficult
