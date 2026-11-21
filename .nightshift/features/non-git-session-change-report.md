# Session-change report for non-Git game directories

`--internal-session-changes` (v37) reports `unavailable` outside Git, so the cleanup inventory there still relies on the agent's own listing. A startup file-listing snapshot (relative path, size, last-write time) persisted per launch and compared at session end would close the gap, but needs a full lifecycle for the stored snapshot (creation, cleanup, crash recovery, launches without a notification channel). Captured 2026-09-23.
