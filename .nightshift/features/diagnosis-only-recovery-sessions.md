# Diagnosis-only recovery sessions

## Goal

When a startup check fails in a way the agent could help diagnose, and the AI host itself can still launch, start the agent in a diagnosis-only session instead of refusing outright. The agent can investigate and help repair the cause, while game modifications stay blocked until the failed check has been rerun and passes. Missing Git is the first case; each further startup failure joins as its own decision.

## Qualifying failures

The spec defines which startup failures qualify and which remain hard refusals. A refusal whose purpose is to keep any code from running, such as a failed bootstrap integrity or trust check, is a likely hard refusal.

## First case: missing Git

Use the fallback backup policy outside Git repositories. When Git metadata exists but Git is unavailable, allow a diagnosis-only agent session while keeping game modifications blocked until Git protection is restored; backups alone do not replace checks for pre-existing repository changes.

## Decisions (v46)

- Qualifying failure: only Git metadata in the game directory or above it with no git command on PATH. Repository inspection failing while git is present (qualifies from v48, below), the dirty-tree abort, integrity, trust and identity failures, and unavailable shared paths stay hard refusals.
- Diagnostic launch and modification authorization: the diagnosis-only session never authorizes game changes. It runs only the trusted executing copy, skips updater replacement, the update stage and the background update check, and captures the startup snapshot in place of the Git preflight.
- Re-running the preflight: the user relaunches, and the full Git preflight runs again. There is no in-session re-check, because a mid-session pass would have to establish a new clean baseline partway through a session the cleanup boundary relies on.

## Second case: repository inspection failing (v48)

- Qualifying failure: Git metadata in the game directory or above it, a git command on PATH, and `git rev-parse --show-toplevel` from the game directory exiting nonzero or printing no repository root. Typical causes are Git's dubious-ownership check, a `.git` file pointing at a missing gitdir and a corrupt `.git`. The reason is `git-inspection-failed`, and the evidence quotes git's exit code and its error output on one line, truncated past a fixed limit.
- Still hard refusals: a repository that rev-parse can inspect but whose status or tracking query fails, a game directory outside the detected work tree, an ambiguous repository root, and the refusals the first case keeps.
- Repair permissions: read-only inspection, including read-only git commands run with --no-optional-locks so they do not refresh the index, needs no approval. Changing Git's global or system configuration, such as adding a safe.directory entry, needs the user's explicit approval, as installing software does. The repository's own data and configuration stay untouched; the agent explains the repair and leaves it to the user.
- Everything else follows the first case: the trusted executing copy only, no update actions, the startup snapshot in place of the Git preflight, and game changes only after a normal relaunch passes.

## Candidate later cases

None identified. [Missing nvidia-smi recovery](missing-nvidia-smi-recovery.md), once listed here, shipped separately in v44 with its own incomplete-facts launch.

Captured 2026-10-21 as Missing Git recovery; rescoped on 2026-10-23 to a general diagnosis-only mode with missing Git as the first case. The missing-Git case was built as v46 on 2026-10-24. The repository-inspection case was built as v48 and published on 2026-10-24.
