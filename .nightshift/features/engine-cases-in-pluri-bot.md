# Engine cases in Pluri-Bot

Move the release suite's engine cases, the ones that test engine behavior on any mission rather than the DLSS mission's own prompt and stores, from DLSS5-Bot into Pluri-Bot with the shared test harness, so Pluri-Bot owns the harness and the copy of its helpers in `tests/Test-PluriBotBase.ps1` ends.

## Context

The repository-home design's step 1 moved only the release-suite cases that read the hello-world base into Pluri-Bot, and named moving the other engine cases as later work tracked as its own backlog entry; this is that entry. Until it ships, `tests/Test-PluriBotBase.ps1` holds verbatim copies of the DLSS5-Bot suite helpers its three cases need, and DLSS5-Bot's release suite still tests engine behavior through the DLSS package.

## Open questions

- Which cases count as engine cases: those that exercise the engine through a fixture mission, as against those that assert the DLSS mission's prompt, stores or post-run checks.
- How DLSS5-Bot then runs the moved cases against its package, or whether its release relies on Pluri-Bot's run of the pinned engine.
- How the harness is shared without a second copy: vendored into DLSS5-Bot beside the engine, or published with each Pluri-Bot release.
