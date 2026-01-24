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

Fetch comments using GraphQL for complete data including resolution status:

```bash
# Get repository info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

# Fetch review threads with resolution status via GraphQL
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            comments(first: 100) {
              nodes {
                author { login }
                body
                path
                line
                createdAt
              }
            }
          }
        }
        reviews(first: 100) {
          nodes {
            author { login }
            body
            state
            createdAt
          }
        }
      }
    }
  }
' -f owner="${REPO%/*}" -f repo="${REPO#*/}" -F pr=<PR>
```

**Note**: For PRs with >100 comments, use pagination with `after` cursor.

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
- **Resolved**: Threads with `isResolved: true` (from GraphQL reviewThreads)
- **Own comments**: Matching username from `gh api user -q '.login'`
- **No Action Required category**: LGTM, +1, approval comments, etc.

### 5. Triage: Auto vs Manual

Separate comments into two groups:

**Auto-addressable** (Claude handles automatically):
- Clear, specific code changes (add null check, fix typo, rename variable)
- Single-file changes with explicit instructions
- Style/formatting fixes
- Simple refactoring within a function

**Requires human decision** (report only, do not auto-fix):
- Specification decisions (e.g., "should this return error or null?")
- Large-scale refactoring across multiple files
- Architecture changes (e.g., "consider using a different pattern")
- Ambiguous or conflicting comments
- Security decisions requiring business context
- Performance trade-offs needing product input
- Changes that might affect external APIs or contracts

### 6. Display Summary

Show categorized results with triage status:

```
## PR #<number> Review Comments

### Auto-addressable (X items)

#### Priority 1: Security
- [ ] auth.ts:42 - "Input sanitization needed" (@reviewer)

#### Priority 2: Bug / Logic Error
- [ ] handler.ts:78 - "Missing null check" (@reviewer)

#### Priority 3: Performance
- [ ] query.ts:100 - "This is an N+1 query" (@reviewer)

#### Priority 4: Maintainability / Design
- [ ] utils.ts:20 - "Rename variable for clarity" (@reviewer)

#### Priority 5: Code Style
- [ ] format.ts:10 - "Fix indentation" (@reviewer)

#### Question / Clarification
- [ ] config.ts:30 - "What's the intent of this setting?" (@reviewer)

### Requires Human Decision (Y items)
- [ ] service.ts:55 - "Consider splitting this into separate services" (@reviewer)
  → Reason: Architecture change across multiple files
- [ ] api.ts:100 - "Should this return 404 or empty array?" (@reviewer)
  → Reason: Specification decision required

---
Auto: X items / Manual: Y items / Excluded: Z items
```

### 7. Select Items to Address

Display interactive checklist for user to select which items to fix:

```
## Select items to address

### Auto-addressable
- [x] 1. auth.ts:42 - "Input sanitization needed" (Security)
- [x] 2. handler.ts:78 - "Missing null check" (Bug)
- [ ] 3. utils.ts:20 - "Rename variable for clarity" (Style)

### Requires Human Decision
- [ ] 4. service.ts:55 - "Consider splitting into separate services"
      → Reason: Architecture change across multiple files
- [ ] 5. api.ts:100 - "Should this return 404 or empty array?"
      → Reason: Specification decision required

Enter item numbers to address (e.g., "1,2,4" or "all" or "auto"):
- all: Address all items (including manual)
- auto: Address only auto-addressable items (default checked)
- Numbers: Address specific items only
```

- Default: All auto-addressable items are pre-checked
- User can uncheck items to skip, or check manual items to include
- If user enters nothing or "auto": proceed with pre-checked items only

### 8. Address Selected Items

Address only user-selected items in priority order.

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

### 9. Final Summary

After all auto-addressable items are addressed, display summary:

```
## Completed

- Code fixes: X items
- Commits created: Y items
- Questions replied: Z items

### Created commits:
- abc1234: fix: resolve null check issue
- def5678: perf: optimize database query

### Requires Human Decision (not addressed):
- service.ts:55 - "Consider splitting this into separate services"
  → Reason: Architecture change across multiple files
- api.ts:100 - "Should this return 404 or empty array?"
  → Reason: Specification decision required
```

### 10. Auto Push

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
