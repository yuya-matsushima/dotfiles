---
description: Create a high-quality GitHub Pull Request (use --auto to skip confirmation)
argument-hint: [<base-branch>] [--auto]
---

# Pull Request Creation Command

## Auto mode detection
Check if $ARGUMENTS contains "--auto" flag.

1. **Argument Parsing**:
   - Check if $ARGUMENTS contains "--auto" flag for auto mode
   - Extract base branch from $ARGUMENTS (first non-flag argument):
     - Remove "--auto" from arguments to get candidate branch name
     - If branch name is provided:
       - Validate: `git rev-parse --verify <branch> 2>/dev/null`
       - If validation fails, ask user: "Branch '<branch>' not found. Use default branch detection? (y/n)"
       - If user answers "no" (n), exit without creating PR
     - If no branch name is provided, auto-detect base branch:
       1. Check `git rev-parse --verify develop 2>/dev/null` → use 'develop' if exists
       2. Check `git rev-parse --verify main 2>/dev/null` → use 'main' if exists
       3. Check `git rev-parse --verify master 2>/dev/null` → use 'master' if exists
       4. If none exist, use 'main' as fallback
   - Store resolved base branch in $BASE_BRANCH variable for use in subsequent steps
2. **Analyze Changes**:
   - Run `git diff $BASE_BRANCH...HEAD` to understand what was changed
   - Run `git log $BASE_BRANCH...HEAD --oneline` to review the commit history and understand context
3. **Context Check**:
   - Read `AGENTS.md` if it exists (not CLAUDE.md, as codex agents follow AGENTS.md)
   - **Language Selection for PR**:
     - If `AGENTS.md` contains specific language rules for PR (e.g., English specification), follow them
     - Otherwise, default to **Japanese** as per AGENTS.md mandate: "すべての回答は日本語で記述すること" (all responses in Japanese)
     - Extract any commit format preferences from AGENTS.md (feat:, fix:, etc.)
4. **Draft PR Content**:
   - **Title**: Create a concise, descriptive title following Conventional Commit format
     - Use format: `<type>(<scope>): <summary>` or `<type>: <summary>` if no scope
     - Max 50 characters (per AGENTS.md requirement)
     - Types: feat, fix, docs, refactor, style, test, perf, chore
     - Examples (Japanese): `feat: ユーザー認証機能を追加`, `fix: ログイン時のバグを修正`
     - Examples (English, if specified in AGENTS.md): `feat: add user authentication logic`, `fix: resolve login bug`
   - **Body**: Write a professional PR description in Markdown. Include:
     - **Summary**: 1-2 sentences describing what this PR accomplishes
     - **Key Changes**: Bullet points listing technical changes (3-5 bullets)
     - **Impact**: Potential side effects, areas requiring review, testing notes
   - **Language**: Use Japanese by default (per AGENTS.md), or English if AGENTS.md specifies
5. **Execution Logic**:
   - **If AUTO_MODE is detected (--auto flag present)**:
     - Push the current branch: `git push origin HEAD`
     - Create the PR: `gh pr create --title "[Generated Title]" --body "[Generated Body]" --assignee @me`
     - Display the final PR URL and summary
   - **Otherwise (Interactive mode)**:
     - Display the drafted PR title and body clearly
     - Show the exact commands that would be executed:
       ```
       git push origin HEAD
       gh pr create --title "[Title]" --body "[Body]" --assignee @me
       ```
     - Ask: "このPRを作成しますか？ (y/n)" (Japanese, default per AGENTS.md)
     - If confirmed (y), execute the commands above
     - If denied (n), cancel without any changes
