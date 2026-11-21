# v65 notes missing outcome: deferred review minors

Paths under `development/` or `development\` in this file name the frozen local archive in the LocalAppData folder the project came from; they are not part of this repository.

Minor findings from the v65 release review of the notes check's missing outcome (`development/v65-notes-missing/`), deferred at release time on 2026-11-18 by the user's decision. None blocked the release. Each is as the reviewer reported it; the mission finding was checked against the mission text, the others were not reproduced.

## Mission

- `MISSION.md`'s game notes rules tell the agent not to create the game notes in a session with a user request appended to its prompt, since such a session never creates them, while the unchanged rule a few lines below says "After using online research, update sources_checked without asking", and `sources_checked` is a game-notes key. A task that needs online research in a game folder without `DLSS5-ADDER.md` therefore gets two conflicting instructions. A fix qualifies one rule, for example so that research in a session that must not create the game notes is reported to the user rather than recorded.

## Tests

- In `tests\Test-DLSS5MissionStores.ps1`, the case 'mission stores notes validation reports absent game notes as missing, which a task session leaves uncreated' says in its failure message that the damage for a folder in place of the game notes comes from the existence check, but `Read-Dlss5GuardedBytes` raises the same "Guarded path has an unexpected type" for a folder, so the assertion cannot tell the two apart. The outcome it asserts is right; only the wording overstates it.

## Documentation

- The Documentation section of `development/v65-notes-missing/2026-11-18-v65-notes-missing-design.md` names the bug's documentation slips but not the two further corrections v65 made in `development/v64-notes-validate/consumers.md` and the v64 design, which scope the session end's read in a diagnosis-only session to one started without a task.
