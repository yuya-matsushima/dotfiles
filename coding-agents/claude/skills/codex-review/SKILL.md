---
name: codex-review
description: Run Codex CLI review and display findings with Claude Code actionability info
argument-hint: [<base-branch>]
---

# Codex Review Command

Run Codex CLI review and display categorized findings with actionability information.

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

**Auto-addressable by Claude Code**:
- Clear, specific code changes (add null check, fix typo, rename variable)
- Single-file changes with explicit instructions
- Style/formatting fixes
- Simple refactoring within a function
- High confidence findings (confidence_score >= 0.7)

**Requires human decision** (not auto-fixable):
- Specification decisions (e.g., "should this return error or null?")
- Large-scale refactoring across multiple files
- Architecture changes (e.g., "consider using a different pattern")
- Ambiguous findings
- Medium confidence findings (0.5 <= confidence_score < 0.7)
- Low confidence findings (confidence_score < 0.5)
- Changes that might affect external APIs or contracts

### 6. Display Results

Show overall assessment and categorized results:

```
## Codex Review Results (base: <base-branch>)

### Overall Assessment
- Correctness: <overall_correctness>
- Confidence: <overall_confidence_score>
- Explanation: <overall_explanation>

### Auto-addressable by Claude Code (X items)

#### P0: Blocking
- src/auth.ts:42-45 - "[P0] SQL injection vulnerability" (confidence: 0.95)

#### P1: High Priority
- src/handler.ts:78-80 - "[P1] Missing null check" (confidence: 0.85)

#### P2: Medium Priority
- src/query.ts:100-105 - "[P2] N+1 query detected" (confidence: 0.80)

#### P3: Low Priority
- src/utils.ts:20 - "[P3] Variable naming could be clearer" (confidence: 0.75)

### Requires Human Decision (Y items)
- src/service.ts:55-70 - "[P2] Consider splitting this service" (confidence: 0.45)
  -> Reason: Low confidence, architecture change across multiple files
- src/api.ts:100-110 - "[P1] Error handling approach unclear" (confidence: 0.60)
  -> Reason: Specification decision required

---
Auto-addressable: X items / Requires human decision: Y items / Total: Z items

To automatically fix auto-addressable items, run: /codex-review-fix
```

**Important**: This skill is read-only. Do not make any modifications to the codebase.

## Examples

```bash
# Review against auto-detected base branch
/codex-review

# Specify base branch explicitly
/codex-review main

# Review against develop branch
/codex-review develop
```

## Notes

- **Read-only**: This skill only displays findings; it does not modify any files
- **No PR required**: Works with any branch, compares against base branch
- **Confidence display**: Shows AI confidence score for each finding
- **Priority order**: Items are displayed in priority order (P0 first)
- **Actionability info**: Each finding includes whether it can be auto-addressed by Claude Code
- **Next step**: To fix issues automatically, use `/codex-review-fix`
