---
description: Create a high-quality GitHub Pull Request (use --auto to skip confirmation)
argument-hint: [<base-branch>] [--auto]
---

# Pull Request Creation Command

## Instructions

**Argument Parsing**:
- Check if $ARGUMENTS contains "--auto" flag for auto mode
- Extract base branch from $ARGUMENTS (first non-flag argument):
  - Remove "--auto" from arguments to get the branch name
  - If branch name is specified:
    - Validate branch exists: `git rev-parse --verify <branch> 2>/dev/null`
    - If invalid, ask user: "Branch '<branch>' not found. Use default branch detection? (y/n)"
    - If no (n), exit without creating PR
  - If no branch name is specified, auto-detect base branch:
    1. Check `git rev-parse --verify develop 2>/dev/null` → use 'develop' if exists
    2. Check `git rev-parse --verify main 2>/dev/null` → use 'main' if exists
    3. Check `git rev-parse --verify master 2>/dev/null` → use 'master' if exists
    4. If none exist, show error: "Error: No default base branch found (tried: develop, main, master). Please specify a base branch explicitly: pr <base-branch> [--auto]" and exit

1. **Analyze Changes**:
   - Run `git diff $BASE_BRANCH...HEAD` to understand exactly what was changed.
   - Run `git log $BASE_BRANCH...HEAD --oneline` to review the commit history and understand the context.
2. **Context Check**:
   - Read `CLAUDE.md` if it exists.
   - **Language Selection for PR**:
     - If `CLAUDE.md` contains specific language rules for PR (English specification), follow them.
     - Otherwise, use **Japanese** as the default language for PR title and body.
3. **Draft PR Content**:
   - **Title**: Create a concise, descriptive title following Conventional Commit format
     - Examples (Japanese): `feat: ユーザー認証機能を追加`, `fix: ログイン時のバグを修正`
     - Examples (English): `feat: add user authentication logic`, `fix: resolve login bug`
   - **Body**: Write a professional PR description in Markdown. Include:
     - **Summary**: What does this PR do? (1-2 sentences)
     - **Key Changes**: Bullet points of technical changes
     - **Impact**: Any potential side effects or areas to review
   - **Language**: Use the language determined in step 2 (Japanese by default, English if specified in CLAUDE.md)
4. **Execution Logic**:
   - **If AUTO_MODE is detected**:
     - Push the current branch: `git push origin HEAD`
     - Create the PR immediately: `gh pr create --title "[Generated Title]" --body "[Generated Body]" --assignee @me`
     - Show the final PR URL and summary
   - **Otherwise (Interactive mode)**:
     - Display the drafted PR title and body
     - Show the exact commands that would be executed:
       ```
       git push origin HEAD
       gh pr create --title "[Title]" --body "[Body]" --assignee @me
       ```
     - Ask: "このPRを作成しますか？ (y/n)" (or in English if applicable: "Do you want to create this PR? (y/n)")
     - If confirmed (y), execute the commands above
     - If denied (n), cancel without any changes
