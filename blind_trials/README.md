# Blind Trials

This directory is organized by artifact type:

- `tasks/`: active benchmark task specs
- `results/`: benchmark notes and judge checklists paired with active tasks
- `fixtures/`: committed helper sources and local benchmark fixtures
- `legacy/`: older standalone tasks and stress programs kept for reference

Conventions:

- active task files live under `blind_trials/tasks/`
- active result files live under `blind_trials/results/`
- task/result pairs should link to each other using those subdirectory paths
- generated build or run outputs for fixture-based benchmarks should stay under the relevant fixture directory in `blind_trials/fixtures/`
