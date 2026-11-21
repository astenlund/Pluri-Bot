# v64 notes validation: deferred review minors

Paths under `development/` in this file name the frozen local archive in the LocalAppData folder the project came from; they are not part of this repository.

Minor findings from the v64 release review of [Mechanical game-notes validation before session end](../features/mechanical-game-notes-validation.md), deferred at release time on 2026-11-17. None blocked the release. Each is as the reviewer reported it; the code findings were not reproduced.

## Behavior

- A task session in a game folder that has no `DLSS5-ADDER.md` yet: `--internal-notes-validate` reports damage for the missing file, since `Read-Dlss5PostRunNotes` reads the target store whenever it is declared and `Read-Dlss5GuardedBytes` cannot open it, while that session's own end reads nothing. The mission's "repair damage in every session" rule may then push the agent to create game notes the task does not need. A fix either reports a missing store as its own outcome or scopes the mission rule for that case.
- `--host` or `--model` placed before `--internal-notes-validate` is refused by the generic `Resolve-Dlss5LaunchArguments` check that covers every `--internal-` mode, which the reviewer reported as exit 4, not the command's usage exit 2. The mission names only the no-argument form, so this is a documentation point unless the exit code should change for every internal mode.
- For a mission other than `dlss5`, a timeout on a free-form store's mutex is reported as damage. This mirrors the plain session end and is recorded so a later change to either keeps them aligned.

## Documentation

These are in the release folder `development/v64-notes-validate/` and the feature records:

- `consumers.md` says "the target display validator case" in `Test-DLSS5Adder.ps1`, but the file has several such cases; it should be plural.
- `consumers.md` says "the list below is complete" where the completeness claim covers the sections below.
- The design says the command takes "each free-form store's mutex" for another mission; only stores that have a mutex are taken (the target store has none).
- The design says "beside the v57 post-run check cases", plural, where one such case exists.
- `.nightshift/features/composable-bootstrap-builder.md` does not mention the mid-session `--internal-notes-validate` command in its post-run checks section.
