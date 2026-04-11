# SKILL.md Header Conventions

Every verified skill should start with YAML frontmatter like:

```yaml
---
name: nim-api-design
description: Design clear public Nim APIs for libraries and modules, including exported types, constructors, lookup functions, error contracts, and container-style interfaces. Use when creating or reviewing a Nim library API, designing an exported module surface, or deciding how callers should construct, access, and validate data.
---
```

## `name`

- Use the skill directory name as the `name`.
- Use lowercase letters, numbers, and hyphens.
- Keep the name stable once the skill is in use.

## `description`

- Treat the description as invocation guidance, not marketing copy.
- Make it specific about what the skill does.
- Include natural trigger phrases users are likely to say.
- Prefer user-facing tasks and outcomes over internal implementation jargon.
- Include both halves:
  - what the skill helps with
  - when to use it
- A good default shape is:

```text
<specific task or outcome>. Use when <natural user requests, files, or situations>.
```

Good:

```yaml
description: Document exported Nim modules and APIs with doc comments that `nim doc` actually picks up, including module docs, proc and type docs, field docs, and runnable examples. Use when writing documentation for a Nim library or fixing docs that are missing, attached to the wrong symbol, or rendering incorrectly.
```

Too internal:

```yaml
description: Choose between `object` and `ref object`, shape lookup surfaces, and encode contracts with `distinct` types.
```

Better:

```yaml
description: Design clear public Nim APIs for libraries and modules, including exported types, constructors, lookup functions, error contracts, and container-style interfaces. Use when creating or reviewing a Nim library API, designing an exported module surface, or deciding how callers should construct, access, and validate data.
```

The goal is to help the model decide to open the skill when a user's request matches it.
