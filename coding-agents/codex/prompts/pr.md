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
       4. If none exist, show error: "Error: No default base branch found (tried: develop, main, master). Please specify a base branch explicitly: pr <base-branch> [--auto]" and exit
   - Store resolved base branch in $BASE_BRANCH variable for use in subsequent steps
2. **Analyze Changes**:
   - Run `git diff $BASE_BRANCH...HEAD` to understand what was changed
   - Run `git log $BASE_BRANCH...HEAD --oneline` to review the commit history and understand context
3. **Context Check**:
   - Read `AGENTS.md` if it exists (not CLAUDE.md, as codex agents follow AGENTS.md)
   - Run `git status -sb` and ensure the working tree is clean before creating a PR
   - (Optional, network) If available, prefer the remote default branch (e.g., `gh repo view --json defaultBranchRef`) over local heuristics
   - **Language Selection for PR**:
     - If `AGENTS.md` contains specific language rules for PR (e.g., English specification), follow them
     - Otherwise, default to **Japanese** as per AGENTS.md mandate: "すべての回答は日本語で記述すること" (all responses in Japanese)
     - Extract any commit format preferences from AGENTS.md (feat:, fix:, etc.)
4. **Draft PR Content**:
   - **Title**: Create a concise, descriptive title following Conventional Commit format
     - Use format: `<type>(<scope>): <summary>` or `<type>: <summary>` if no scope
     - Keep it concise; do not enforce a hard limit unless AGENTS.md explicitly requires it
     - Types: feat, fix, docs, refactor, style, test, perf, chore
     - Examples (Japanese): `feat: ユーザー認証機能を追加`, `fix: ログイン時のバグを修正`
     - Examples (English, if specified in AGENTS.md): `feat: add user authentication logic`, `fix: resolve login bug`
   - **Body**: Write a professional PR description in Markdown. Include:
     - **Summary**: 1-2 sentences describing what this PR accomplishes
     - **Key Changes**: Bullet points listing technical changes (3-5 bullets)
     - **Impact**: Potential side effects, areas requiring review, testing notes
     - **Verification**: Commands or manual checks performed (as required by AGENTS.md)
   - **Language**: Use Japanese by default (per AGENTS.md), or English if AGENTS.md specifies
5. **Execution Logic**:
   - **If AUTO_MODE is detected (--auto flag present)**:
     - Display a brief summary (title, key changes, and a short diff summary) before executing
     - Push the current branch: `git push origin HEAD`
     - **Safety**: Never pass the PR body directly inside double quotes (backticks will execute). Always write the body to a temp file using a single-quoted heredoc:
       ```
       cat <<'EOF' > /tmp/pr-body.md
       ...body...
       EOF
       ```
     - Create the PR with `gh pr create --title "[Generated Title]" --body-file /tmp/pr-body.md --assignee @me`
     - Display the final PR URL and summary
   - **Otherwise (Interactive mode)**:
     - Display the drafted PR title and body clearly
     - Show the exact commands that would be executed:
       ```
       git push origin HEAD
       cat <<'EOF' > /tmp/pr-body.md
       ...body...
       EOF
       gh pr create --title "[Title]" --body-file /tmp/pr-body.md --assignee @me
       ```
     - Ask: "このPRを作成しますか？ (y/n)" (Japanese, default per AGENTS.md)
     - If confirmed (y), execute the commands above
     - If denied (n), cancel without any changes
