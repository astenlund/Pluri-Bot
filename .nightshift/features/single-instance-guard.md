# Single-instance guard

Paths under `development/` in this file name the frozen local archive in the LocalAppData folder the project came from; they are not part of this repository.

Prevent the user from running several DLSS5-ADDER sessions at once where they could interfere. Today no session-wide guard exists: the bootstrap lock and the notes mutexes (`Local\DLSS5-ADDER-MACHINE-NOTES`, `Local\DLSS5-ADDER-PROJECT-KNOWLEDGE`) are each held only around individual operations, and target-directory notes take no lock at all, so two sessions in the same game directory can both run agents that edit the game files and its notes. Connected to [Composable AI bootstrap builder](composable-bootstrap-builder.md), which intends sessions at two different locations not to contend (one mutex per location folder) and lists a session running at a location during Pack up as an open state.

## Settled design

- Engine-level, mission-neutral: the guard is engine machinery keyed by the directory a session works in, not DLSS-specific code, so future packages built on the composable engine get it without mission content of their own. For the DLSS mission that directory is the game directory. Mission content cannot disable it.
- Scope: one guard per working directory, so sessions in different directories (different games) still run side by side.
- Coverage: normal and diagnosis-only agent sessions, absorb (run by a drop onto the .cmd), and every menu or update-box choice that writes the copy or location state (today Arm, Disarm, and both of the update box's choices, Accept and re-arm and Keep disarmed; later Pack up). Explode and read-only views are not guarded.
- Second launch: refuses at once, writing nothing, with a message naming the running holder (process ID, start time, host) and how to reach or end it. It does not wait.
- Holder liveness: a Windows named mutex, whose name derives from the normalized directory path, held for the guarded operation's lifetime. Windows releases an abandoned mutex when its process exits, so a crashed or killed console leaves no stale lock, and acquiring an abandoned mutex counts as a successful acquisition.

## Decided in the v52 design

The v52 spec (`development/v52-single-instance-guard/2026-11-02-v52-single-instance-guard-design.md`) settles the two questions this record left open, and extends the coverage to code that arrived after graduation:

- Folder identity instead of path normalization: the guard is keyed by the folder's volume serial and file ID, read through a handle that follows reparse points, so case, short names, trailing separators and junctions cannot split one folder; a file system without file IDs falls back to a hash of the folder's volume-GUID final path, and a folder that yields neither refuses the operation. The builder's per-location guard for Pack up can reuse this identity.
- Holder record: the holder writes `guards\<token>.json` under the AppData store (process ID, start time, operation, host); a refusal names the holder only when the record names a live process with that start time, and otherwise says the holder's details are unavailable.
- Coverage added since graduation: v51 Configure's project config and seed writes are guarded and its machine config writes are not; a startup update of a copy whose folder is held is skipped for that launch; an adoption approved inside the holding session runs under that session's hold, verified by the process ancestry.

Captured 2026-10-25. Graduated 2026-11-01 with the scope, coverage, second-launch and liveness decisions above.
