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
   - **Safety**: Never embed backticks or user-generated content directly inside double-quoted shell arguments. Use a temp file to avoid command substitution.
   - **If $ARGUMENTS contains "--auto"**: Show the proposed commit message and a brief staged-change summary, then:
     - Write message to a temp file via `cat <<'EOF' > /tmp/commit-msg.txt` (or `mktemp`)
     - Execute `git commit -F /tmp/commit-msg.txt` without asking for confirmation
     - Display the commit message after execution
   - **Otherwise**: Show the proposed command `git commit -F /tmp/commit-msg.txt`, ask for confirmation "Proceed with this commit? (y/n)", and execute only if confirmed.
