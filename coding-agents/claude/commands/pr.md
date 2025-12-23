# Description
Create a high-quality GitHub Pull Request by analyzing code changes.

# Instructions
1. **Analyze Changes**:
   - Run `git diff main...HEAD` (or the base branch) to understand exactly what was changed.
   - Review the commit history to understand the context.
2. **Draft PR Content**:
   - **Title**: Create a concise, descriptive title (e.g., "feat: add user authentication logic").
   - **Body**: Write a professional PR description in Markdown. Include:
     - **Summary**: What does this PR do?
     - **Key Changes**: Bullet points of technical changes.
     - **Impact**: Any potential side effects or areas to review.
3. **Execution**:
   - Push the current branch: `git push origin HEAD`.
   - Create the PR using the drafted content:
     `gh pr create --title "[Generated Title]" --body "[Generated Body]" --assignee @me`
4. **Final Result**:
   - Show the user the final PR URL and a summary of what you wrote.
