---
description: Create a high-quality GitHub Pull Request (use --auto to skip confirmation)
argument-hint: [--auto]
---

# Pull Request Creation Command

## Instructions

**Auto mode detection**: Check if $ARGUMENTS contains "--auto" flag.
1. **Analyze Changes**:
   - Run `git diff main...HEAD` (or the base branch) to understand exactly what was changed.
   - Review the commit history to understand the context.
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
