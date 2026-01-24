---
name: codex-review-fix
description: Run Codex CLI review and address issues sequentially with commits
argument-hint: [<base-branch>]
---

# Codex Review Fix Command

Automatically run Codex CLI review, categorize findings, and address each issue with commits.

## Instructions

### 1. Determine Base Branch

**Determine base branch**:
- If branch is specified in `$ARGUMENTS`: use that branch
- If not specified: run `scripts/detect-base-branch.sh` (located relative to this SKILL.md)
- If detection fails: display error message and exit

### 2. Run Codex Review

Execute Codex CLI with JSON output:

```bash
codex exec review --base <base-branch> --json
```

**Expected JSON output format**:

```json
{
  "findings": [
    {
      "title": "[P1] Missing null check in handler",
      "body": "Markdown explanation...",
      "confidence_score": 0.85,
      "priority": 1,
      "code_location": { "file": "src/handler.ts", "line_start": 42, "line_end": 45 }
    }
  ],
  "overall_correctness": "patch is correct",
  "overall_explanation": "...",
  "overall_confidence_score": 0.9
}
```

### 3. Parse JSON and Extract Findings

Parse the JSON output and extract the `findings` array. Each finding contains:
- `title`: Issue title with priority prefix (e.g., "[P1]")
- `body`: Detailed description in Markdown
- `confidence_score`: AI confidence level (0.0-1.0)
- `priority`: Priority level (0-3)
- `code_location`: File path and line numbers

### 4. Categorize by Priority

Categorize findings by **priority level**:

| Priority | Level | Description | Examples |
|----------|-------|-------------|----------|
| P0 | Blocking | Critical issues that must be fixed | Security vulnerabilities, critical bugs |
| P1 | High | Should fix in next cycle | Bugs, logic errors |
| P2 | Medium | Fix eventually | Performance issues, maintainability |
| P3 | Low | Nice to have | Code style improvements |

### 5. Triage: Auto vs Manual

Separate findings into two groups:

**Auto-addressable** (Claude handles automatically):
- Clear, specific code changes (add null check, fix typo, rename variable)
- Single-file changes with explicit instructions
- Style/formatting fixes
- Simple refactoring within a function
- High confidence findings (confidence_score >= 0.7)

**Requires human decision** (report only, do not auto-fix):
- Specification decisions (e.g., "should this return error or null?")
- Large-scale refactoring across multiple files
- Architecture changes (e.g., "consider using a different pattern")
- Ambiguous findings
- Medium confidence findings (0.5 <= confidence_score < 0.7)
- Low confidence findings (confidence_score < 0.5)
- Changes that might affect external APIs or contracts

### 6. Display Summary

Show overall assessment and categorized results:

```
## Codex Review Results (base: <base-branch>)

### Overall Assessment
- Correctness: <overall_correctness>
- Confidence: <overall_confidence_score>
- Explanation: <overall_explanation>

### Auto-addressable (X items)

#### P0: Blocking
- [ ] src/auth.ts:42-45 - "[P0] SQL injection vulnerability" (confidence: 0.95)

#### P1: High Priority
- [ ] src/handler.ts:78-80 - "[P1] Missing null check" (confidence: 0.85)

#### P2: Medium Priority
- [ ] src/query.ts:100-105 - "[P2] N+1 query detected" (confidence: 0.80)

#### P3: Low Priority
- [ ] src/utils.ts:20 - "[P3] Variable naming could be clearer" (confidence: 0.75)

### Requires Human Decision (Y items)
- [ ] src/service.ts:55-70 - "[P2] Consider splitting this service" (confidence: 0.45)
  -> Reason: Low confidence, architecture change across multiple files
- [ ] src/api.ts:100-110 - "[P1] Error handling approach unclear" (confidence: 0.60)
  -> Reason: Specification decision required

---
Auto: X items / Manual: Y items / Total: Z items
```

### 7. Select Items to Address

Display interactive checklist for user to select which items to fix:

```
## Select items to address

### Auto-addressable
- [x] 1. src/auth.ts:42-45 - "[P0] SQL injection vulnerability" (P0, confidence: 0.95)
- [x] 2. src/handler.ts:78-80 - "[P1] Missing null check" (P1, confidence: 0.85)
- [ ] 3. src/utils.ts:20 - "[P3] Variable naming" (P3, confidence: 0.75)

### Requires Human Decision
- [ ] 4. src/service.ts:55-70 - "[P2] Consider splitting this service"
      -> Reason: Low confidence, architecture change
- [ ] 5. src/api.ts:100-110 - "[P1] Error handling approach unclear"
      -> Reason: Specification decision required

Enter item numbers to address (e.g., "1,2,4" or "all" or "auto"):
- all: Address all items (including manual)
- auto: Address only auto-addressable items (default checked)
- Numbers: Address specific items only
```

- Default: All auto-addressable items are pre-checked
- User can uncheck items to skip, or check manual items to include
- If user enters nothing or "auto": proceed with pre-checked items only

### 8. Address Selected Items

Address only user-selected items in priority order (P0 -> P1 -> P2 -> P3).

For each selected finding:
1. Read the target file at `code_location.file`
2. Review lines from `line_start` to `line_end`
3. Modify code according to the finding's `body` description
4. Stage changes: `git add <file>`
5. Run `/commit --auto` with Codex review reference

**Commit message format**:

```
<type>(<scope>): <short summary> (50 chars or less)

<Explain the reason and content of the change>

Codex review finding:
- [P<priority>] <title> (<file>:<line_start>-<line_end>)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Example:
```
fix(handler): add null check for user input

Added null check before accessing user.id to prevent
potential runtime error when user object is undefined.

Codex review finding:
- [P1] Missing null check in handler (src/handler.ts:42-45)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 9. Final Summary

After all selected items are addressed, display summary:

```
## Completed

- Findings addressed: X items
- Commits created: Y items

### Created commits:
- abc1234: fix(auth): sanitize SQL query parameters
- def5678: fix(handler): add null check for user input

### Addressed findings:
- [x] src/auth.ts:42-45 - "[P0] SQL injection vulnerability"
- [x] src/handler.ts:78-80 - "[P1] Missing null check"

### Not addressed (requires human decision):
- src/service.ts:55-70 - "[P2] Consider splitting this service"
  -> Reason: Low confidence, architecture change
- src/api.ts:100-110 - "[P1] Error handling approach unclear"
  -> Reason: Specification decision required
```

## Examples

```bash
# Review against auto-detected base branch
/codex-review-fix

# Specify base branch explicitly
/codex-review-fix main

# Review against develop branch
/codex-review-fix develop
```

## Notes

- **No PR required**: Works with any branch, compares against base branch
- **Interactive selection**: User selects which items to address via checklist (Step 7)
- **Commit granularity**: Each finding is addressed with an individual commit
- **Confidence display**: Shows AI confidence score for each finding
- **Priority order**: Items are processed in priority order (P0 first)
- **When unable to address**: Skip the item and include in "Not addressed" summary
