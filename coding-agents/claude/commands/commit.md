---
description: Analyze staged changes and commit using CLAUDE.md rules or default Conventional Commits.
---

# commit command

1. **Check Staged Changes**: Run `git diff --cached`. If there are no changes, inform the user and stop.
2. **Determine Guidelines**:
   - Read `CLAUDE.md` if it exists.
   - **Rule Priority**:
     1. If `CLAUDE.md` has specific commit guidelines, follow them strictly.
     2. Otherwise, use **Conventional Commits** (e.g., `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `style:`, `test:`, `perf:`).
3. **Generate Message**:
   - **Title**: `<type>(<scope>): <short summary>` (Max 50 characters).
   - **Body**: Explain the "why" and "what" of the change.
   - **Language**: Default to Japanese unless `CLAUDE.md` or the user specifies otherwise.
4. **Review & Confirm**:
   - Display the proposed commit message clearly.
   - Ask the user: "Do you want to proceed with this commit? (y/n)"
5. **Execution**: If confirmed, run `git commit -m "[generated message]"`.
