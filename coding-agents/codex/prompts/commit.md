---
description: Analyze staged changes and commit using AGENTS.md rules (use --auto to skip confirmation)
argument-hint: [SCOPE=<scope>] [--auto]
---

# commit command instructions

## Auto mode detection
Check if $ARGUMENTS contains "--auto" flag.

1. **Context Acquisition**:
   - Run `git status` to confirm what is staged and ensure no unintended files are included.
   - Run `git diff --cached` to see staged changes.
   - Read `AGENTS.md` in the project root to identify specific rules.
2. **Strategy**:
   - IF `AGENTS.md` has specific guidelines, follow them.
   - ELSE, default to **Conventional Commits** (feat, fix, chore, docs, etc.).
3. **Drafting**:
   - Title: `<type>($SCOPE): <summary>` (Max 50 chars). If no scope is provided, omit `($SCOPE)`.
   - Body: Explain the "Why" behind the changes. If AGENTS.md requires a specific format, follow it.
   - Language: Default to Japanese unless the user explicitly requests another language.
4. **Execution Logic**:
   - **If $ARGUMENTS contains "--auto"**: Show the proposed commit message and a brief staged-change summary, then execute `git commit -m "[message]"` without asking for confirmation. Display the commit message after execution.
   - **Otherwise**: Show the proposed command: `git commit -m "[message]"`, ask for confirmation "Proceed with this commit? (y/n)", and execute only if confirmed.
