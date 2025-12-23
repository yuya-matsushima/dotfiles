---
description: Analyze staged changes and commit using AGENTS.md rules or default Conventional Commits.
argument-hint: [SCOPE=<scope>]
---

# commit command instructions

1. **Context Acquisition**:
   - Run `git diff --cached` to see staged changes.
   - Read `AGENTS.md` in the project root to identify specific rules.
2. **Strategy**:
   - IF `AGENTS.md` has specific guidelines, follow them.
   - ELSE, default to **Conventional Commits** (feat, fix, chore, docs, etc.).
3. **Drafting**:
   - Title: `<type>($SCOPE): <summary>` (Max 50 chars).
   - Body: Explain the "Why" behind the changes.
   - Language: Default to Japanese unless specified otherwise.
4. **Finalization**:
   - Show the proposed command: `git commit -m "[message]"`
   - Ask for confirmation: "Proceed with this commit? (y/n)"
