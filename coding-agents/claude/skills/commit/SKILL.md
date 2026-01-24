---
name: commit
description: Analyze staged changes and commit using CLAUDE.md rules (use --auto to skip confirmation)
argument-hint: [--auto]
---

# commit command

**Auto mode detection**: Check if $ARGUMENTS contains "--auto" flag.

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
   - **Co-Authored-By**: Always end the commit message with `Co-Authored-By: Claude <noreply@anthropic.com>`
4. **Execution Logic**:
   - **If AUTO_MODE is detected**: Execute `git commit -m "[generated message]"` immediately without asking for confirmation. Display the commit message after execution.
   - **Otherwise**: Display the proposed commit message clearly, ask "Do you want to proceed with this commit? (y/n)", and execute only if confirmed.
