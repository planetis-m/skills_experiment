# Blind Benchmark Prompt

## Setup

1. Create two blind skill files: `group_x_skill.md` and `group_y_skill.md`
2. Copy the original skill to one, the verified skill to the other
3. Do NOT record which is which in any file
4. Create isolated directories: `blind_trials/{A1,A2,A3,B1,B2,B3}`

## Generator Phase

Spawn 6 subagents (3 per group), each writing to its own isolated directory with an absolute output path:

- Group A (A1-A3): read `group_x_skill.md`
- Group B (B1-B3): read `group_y_skill.md`

Each subagent receives:
1. The path to its assigned skill file (read it for guidance)
2. The task specification (create subject_solution.nim implementing a refcounted CoW String)
3. An absolute output path (e.g., `/path/to/blind_trials/A1/subject_solution.nim`)
4. Instruction to verify compilation after writing

## Evaluation Phase

After all subagents complete, evaluate each trial against 8 criteria:

1. **COMPILE** — compiles with `nim c --mm:orc`
2. **HOOK_SIGS** — `=destroy` takes `T` (not `var T`), `=wasMoved` takes `var T`
3. **NO_NIL** — no field assignments inside `=destroy`
4. **SELF_ASSIGN** — `=copy` has self-assignment protection
5. **NODUP** — `=dup` uses `{.nodestroy.}`
6. **COW** — `mutateAt` implements CoW when counter > 1
7. **STRESS** — passes stress test suite (refcount, CoW, self-copy, move, empty string)
8. **MEMORY_SAFE** — Valgrind 0 errors, 0 leaks

Write verdict JSON per trial. Aggregate by group.

## Unblinding

After evaluation, reveal which skill is Group X and which is Group Y. Compare aggregate scores.

## Key Rules

- **No result poisoning**: the evaluator must not know which skill is which during evaluation
- **Absolute paths**: subagents must write to absolute paths, not relative cwd
- **Simple**: Generator produces code → Evaluator checks it. No intermediate phases.
- **Sample size**: 3 per group is minimum. 10+ for statistical significance.
