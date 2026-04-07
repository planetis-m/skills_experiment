# Phase 1 Prompt: Claim Extraction

Read the file at `~/.agents/skills/nim-ownership-hooks/SKILL.md` (or the provided skill file).

Extract every technical claim, assumption, or rule from the document. A "claim" is any statement about Nim compiler behavior, hook semantics, or recommended practice that can be proven true or false through code.

Output a structured JSON array where each entry has:
- `claim_id`: unique identifier (C01, C02, ...)
- `claim_text`: the exact claim text
- `is_testable`: true if it can be verified with a Nim program, false if it requires external knowledge

Save to `nim-ownership-hooks_dataset.json`.
