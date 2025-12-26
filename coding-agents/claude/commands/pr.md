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
2. **Draft PR Content**:
   - **Title**: Create a concise, descriptive title (e.g., "feat: add user authentication logic").
   - **Body**: Write a professional PR description in Markdown. Include:
     - **Summary**: What does this PR do?
     - **Key Changes**: Bullet points of technical changes.
     - **Impact**: Any potential side effects or areas to review.
3. **Execution Logic**:
   - **If AUTO_MODE is detected**:
     - Push the current branch: `git push origin HEAD`
     - Create the PR immediately: `gh pr create --title "[Generated Title]" --body "[Generated Body]" --assignee @me`
     - Show the final PR URL and summary
   - **Otherwise**:
     - Display the drafted PR title and body
     - Ask: "Do you want to create this PR? (y/n)"
     - If confirmed, push and create the PR with the command above
