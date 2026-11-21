# Composable AI bootstrap builder

Paths under `development/` in this file name the frozen local archive in the LocalAppData folder the project came from; they are not part of this repository.

## Goal

Evolve DLSS5-ADDER into a general AI-powered deployment tool. A universal base .cmd ships with a harmless hello-world mission and becomes a self-contained package tailored to a purpose, such as DLSS game maintenance or server certificate rotation.

## Terms

- **Engine:** the shared launch and packaging mechanics, grown out of today's PowerShell payload between the payload markers once the DLSS-specific prompt and sections are moved to mission content. This entry does not reuse the word payload for anything else.
- **Mission content:** the task-specific content, meaning everything Explode writes plus the baked machine config seed. The engine and the mission content are kept separate behind clear markers.
- **Mission hash:** a hash over the decoded bytes of every mission content file, the baked seed included.
- **Host:** the AI host program.
- **Location and role:** a location is the .cmd's machine and directory. Role belongs to the location: it is the target where the declared target assertion holds and dev otherwise, so dev and target can share a machine, as the AppData copy and the game directories do today.
- **Arm state and test records:** engine state embedded in the .cmd outside the hashed mission content, so they travel with a copy.

## Execution and updates

- Execute launches an AI agent unless the mission declares the scripted execution mode (see Scripted execution and export), where the agent is the fallback. The other menu operations launch an agent only where stated.
- The Engine-only auto-update slice replaces the engine and re-embeds the installed mission content unchanged, for a DLSS copy whose published form is not this machine's whole-file record for its version, which is how an edited mission shows (user decisions, 2026-11-11; spec `development/v59-engine-update/2026-11-11-v59-engine-update-design.md`). A copy whose published form matches that record keeps the whole-file update, so the engine and the release's mission arrive together, and packages of other missions do not update. Before an engine-only write the release's own engine checks the result, and a refusal skips the update.
- That re-embed of unchanged mission content is not a mission content write, so it keeps the test records, since the mission hash is unchanged, but it still disarms the package. Re-arming is then one menu action while the gate still passes, and the user may rerun tests first.
- In an engine-only update the release's mission is not applied with the engine. When it differs from the mission the edit replaced, or that mission is unknown, it is offered separately and the user chooses whether to take it; taking it is a mission content write, so it disarms the package and removes its test records.
- Status, 2026-11-11: the slice shipped as bootstrap v59, installed as the canonical AppData copy and published to the gist at revision `f276e255286c340f8890a606185d10c78d25357b` (SHA-256 `c2024846960308d41c90fbb730310b38e08bd8f4562b656686238a47a1d11d2b`). Because the engine applying an update is the copy's own, engine-only updates start with updates a v59 or later engine applies; an update a v58 or earlier engine applies still replaces the whole file and arrives disarmed.
- A later slice, AI-assisted mission merge, offers an AI-assisted merge wherever the what's-changed box offers to take the release's mission: when the copy's mission has changes of its own and the release's mission differs from the one the edit replaced or that one is unknown, beside taking or keeping either one (user idea, 2026-11-11). The merge result is a mission content write that keeps the edit as the `.bkp` and records the release's mission as the one the edit replaced, and a result that, with the copy's own seed, equals the release's mission is written as Take writes it (spec `development/v60-mission-merge/2026-11-11-v60-mission-merge-design.md`).
- Status, 2026-11-16: the AI-assisted mission merge slice shipped as bootstrap v60, installed as the canonical AppData copy and published to the gist at revision `81da5283517f15b20f1e232199871d8ad22b8268` (SHA-256 `7a8aee8ae1c61657bac577b2e69c8922aa9b72d6b9b9675c0692a70823fa38d8`). A copy's first mission content write that records the published mission it replaced, and a merge not written as Take, keep that mission as an ancestor in `engine\mission-ancestors\`, so a merge is three-way when this machine holds the ancestor and two-way otherwise. The live merge probe passed with Claude Code 2.1.325 and Codex CLI 0.166.0 (`development/v60-mission-merge/probe-merge-20261116T100140Z.json`).

## Trust

- Trust covers the engine hash alone. Mission content, arm state, test records and cargo are data outside the trust gate.
- A hand edit can therefore arm a package that never ran its tests. For a personal tool this is accepted, with no replacement safeguard.
- Execute still re-evaluates the whole Arm gate, and the menu shows the mission hash.

## Menu and entry points

- All operations run from a menu shown on double-click, with no command-line switches required of the user. Dragging files onto the .cmd is the one other user-facing entry point and triggers absorb.
- Absorb is not a menu item. A drop runs it automatically: the console opens to show its progress and then shows the menu.
- Each menu item apart from the Stores view, and absorb, is also reachable through an internal argument so engine tests and automated assembly can drive it headless. The Stores view has none, and a headless Clear was deliberately left out of v57. Neither do the what's-changed box's Take and Merge choices, since Merge needs the user and an agent session.
- The menu header shows the arm state (disarmed or armed), the mission hash, the Arm-gate status with, for each required test, the record the gate consults and the location it ran at, and the declared target. With Pack up it also shows cargo (see Pack up).
- The menu lists the path of every enabled store, the transcript, the engine-owned store, the machine config and every folder Unpack has written, each with an option to open it and, for mission stores and the transcript, to clear it, so persistent state is never hidden from the user. It lists the helper gallery path beside the stores.
- The menu states that the seed and the test records carry identifying data (account name, machine and directory identity) that travels with every copy.

## Explode and absorb

- Explode is a menu item rather than the bare double-click action, since the menu owns double-click. It writes the mission content as editable files beside the .cmd (MISSION.md for the prompt, HELPERS.ps1, tests, project config) and prompts before overwriting exploded files that already exist.
- Absorb takes files dragged and dropped onto the .cmd, or handed over by an authoring item, identified by name rather than argument order. It embeds them base64-encoded for a byte-exact round-trip, verifies by re-exploding to scratch and comparing, and only then deletes the originals.
- The engine embeds no secret of its own. Absorb warns when authored files contain secret-like patterns, since authored content is the user's responsibility.
- Every write to the .cmd's embedded sections (mission content, arm state, test records, cargo) goes through the atomic self-replacement under the bootstrap lock and re-reads the current file inside the lock, so a concurrent write is never lost.
- Every write to mission content (absorb, mission file removal, Configure writing embedded project config, baking the seed) disarms the package and invalidates recorded test results, whether or not the bytes changed.

## Dev mode and the helper gallery

- A Dev mode menu item marks the current machine as a dev machine. It is recorded in machine config against the machine id, so it never travels with a copy, and it is independent of the location role.
- Only on a machine in dev mode does absorb also copy each helper's script bytes into a global helper gallery under LocalAppData. Each entry is stored together with a small manifest the helper declares in the style of an MCP tool declaration: name, purpose, parameters with types and descriptions, which of the probe, apply and verify paths it exposes, and whether it is read-only.
- The gallery is machine state outside mission content, so it never affects the mission hash. Entries are keyed by name and content hash, so a changed helper becomes a new version rather than overwriting.
- Authoring items offer matching gallery helpers for reuse before writing new ones.

## Authoring a new mission

- New mission explodes first when no exploded files exist (with Explode's overwrite prompt otherwise) and launches the AI agent in an authoring role over them. The agent interviews the user, writes MISSION.md, adds the helpers the mission needs, optionally adds tests, and hands back to the engine.
- The engine shows the user the exploded files for review and then absorbs them without a drag, so hand editing and AI authoring converge on the same absorb and verification path.
- An authoring agent, in New mission or in distillation, must not run the mission or touch the engine.

## Tests

- Tests travel with the package: unit tests and read-only live probes for each helper, plus optional end-to-end scenarios.
- Helpers expose separate probe and apply paths and, when they back a post-run check, a read-only verify path. Unit tests cover every path; live probes cover only the read-only ones.
- Scenarios run the agent for an agent-mode mission and the helpers for a scripted one.
- Each test carries a user-authored declaration of whether the Arm gate requires it, the location role it runs at (dev or target) and, for a target test, whether its pass must come from the very location evaluating the gate. A required test with that last property is target-only. A dev test's pass always travels with the copy, since the gate is evaluated wherever Arm or Execute runs.
- The user chooses what to run from the menu at each location.
- Every result is recorded as test name, verdict, mission hash, location identity (machine and directory), the location's role (dev or target) at run time and time only, never test output.

Status, 2026-11-07: bootstrap v55 builds this slice's standalone tests (spec `development/v55-tests-arm-gate/2026-11-07-v55-tests-arm-gate-design.md`): `TEST.<name>.ps1` mission files declared in `PROJECT.json`, records in the STATE section, the Arm gate on Arm, Execute and the what's-changed box, and the identifying-data notice. End-to-end scenarios wait for the post-run checks of the Stores slice, and per-helper probe and apply tests for the helpers of the Authoring slice (user decision, 2026-11-07). The slice shipped as bootstrap v55, installed as the canonical AppData copy and published to the gist at revision `7bd3e498008c8958bc410ea93f16a8b35a9582cf` (SHA-256 `2a10740475c8634f0246c95fb9e0bfc2846f64c9f74a57ed46cb0a757f1e2365`) on 2026-11-08.

## Arming and Execute

- A new package, the shipped hello-world included, starts disarmed with no test records.
- Arm is offered on a disarmed copy and arms only when, for every test the mission requires, the most recent record that matches that test's declaration is a pass on the current mission hash; otherwise it shows the gate status and arms nothing. A matching record has the dev role for a dev test, the target role for a target test and, for a target-only test, the very location evaluating the gate.
- A mission that requires no tests arms after the user confirms that choice explicitly.
- A failing run of a required test recorded into an armed package disarms it when that record is the one the gate would consult.
- Execute appears only when armed, re-evaluates the whole Arm gate before running, refuses when the mission's declared target assertion does not hold, and by default disarms after success. The rerun setting in project config keeps rerunnable missions armed.

### Dev-to-target flow

- Because arm state and test records travel with a copy, arming at the dev location before copying to the target is the intended flow when every required test is a dev test.
- A required target test counts only a run recorded with the target role. It is therefore either run on the target and the package armed there, or, unless it is target-only, run on a target and the .cmd copied back to dev to arm.
- Any mission content write on the target (absorb, mission file removal, embedded project config, seed baking) invalidates every test record, including those of dev tests, which cannot be rerun there, so mission edits belong at the dev location. Local machine config on the target is not a mission content write.

## Configuration

- Configure splits machine config from project config.
- Machine config holds the host CLI, model, paths, and the account the host must be signed in as, checked against the live sign-in, never a credential. It is stored under LocalAppData. From v51 it holds the host, one host path, per-host model and effort, and the expected account for Claude Code only.
- Project config is embedded and holds the approval mode, target assertion, rerun setting, execution mode, store declarations and the transcript option. From v51 it holds the mission id, rerun, approval mode and target assertion, and from v57 the store declarations (`stores`) and post-run checks (`post_run_checks`); execution mode and the transcript option arrive with their own slices.
- The approval mode (default, manual or auto) is the initial permission mode the engine maps onto the host at every agent launch of the mission (from v51 Execute, a command-line task and Diagnose; later also a scenario run); default leaves the host's own configuration in charge. Codex cannot enforce strict prompting, so a manual mission refuses to launch on Codex. The host's own controls can still change it during the session. Authoring launches (New mission, distillation) always start in manual mode, and the hello-world ships in default. An allowlist of specific tools (the mission's helpers among them) is deferred: the v51 live probe showed that Claude Code's `--allowedTools` adds to the user's own allow rules instead of restricting the session to them and splits a malformed rule on its spaces, so the mode returns only if a host offers an exclusive allowlist.
- Machine config can be baked into the package as a seed that a local config overrides field by field. From v51 the engine validates the seed at every agent launch of a package that carries one, on a new machine and every later one alike, and keeps no record of a first run.

## Mission memory stores

- Mission memory stores are declared per mission in project config. Today's three notes files (target-directory notes, machine notes and project knowledge under LocalAppData) become optional slots the mission enables individually, from none at all to all three.
- Each store has a declared format: either the current marker-delimited keyed grammar with a known key order, or free-form Markdown the agent reads and rewrites whole. Its location is not declared; it follows from the slot and the mission (user decision, 2026-11-09).
- Engine writes go through the existing atomic temp-file-and-replace step. The current keyed writer renders and re-parses the grammar, so free-form needs its own writer on top of that step.
- Agent writes follow the prompt's candidate-file protocol as today, extended with a free-form variant.
- Locking stays as today: the bootstrap lock and a mutex for machine notes, a mutex for project knowledge, and none for target-directory notes.
- The generated prompt includes rules only for enabled stores and only in the declared format. Keyed stores generate the grammar and write rules, while the inspection sentences stay in the mission template for its author to adjust; free-form stores generate the listing, the inspection rule and the write protocol.
- The engine never creates or writes an undeclared mission store. The exceptions are compatibility operations: the trust mirror in the machine notes and the legacy hardware key move. Separately, a `dlss5` session whose mission does not declare the target store reads the game notes, when they exist, to look for a legacy transaction marker.

Status, 2026-11-09: shipped in bootstrap v57 (gist revision 060244cef0249c3b2f7a985c4f81cc7477fcc5a8, SHA-256 edc954d8db69bfb2ce72bec2fcdf553fd2e0e1292ccd71fd230998561dd730a6), which built the rest of this slice (spec `development/v57-stores/2026-11-09-v57-stores-design.md`). End-to-end scenarios no longer wait on this slice and remain unbuilt. User decisions, 2026-11-09: the keyed format is for the `dlss5` mission only and every other mission uses free-form, whose machine and knowledge stores live in a per-mission folder and whose target store sits beside the package; `display-targets` is valid only for `dlss5`.

### Keys that are not mission memory

The notes files also hold keys that are not mission memory. The classes below come with examples rather than a complete list, so the implementer sweeps every key the engine reads or writes.

- Keys the engine writes with values of its own, beyond seeding a known key empty: schema versions and status fields in all three files; timestamps in machine notes and target-directory notes; bootstrap trust and checksums and hardware probe results in machine notes; the game fingerprint that guards against the wrong directory and the game identity keys in target-directory notes. The agent also writes some of these, such as the target-directory status.
- Agent-written recovery markers the prompt's resume rules rely on, such as the transaction status marker in target-directory notes.
- Agent-written keys the engine reads to decide the session outcome: the target display keys, which the session-end display check reads, marking the visual verification and status fields when display validation is still pending and failing the exit code on any display problem.

Before the slots become optional:

- Engine-owned keys move to an engine-owned store.
- Shared keys are split into an engine part and an agent part.
- Each agent-written recovery marker or shared key gets an explicit write channel the engine provides.
- Each engine-read agent key is either generalized into a mission-declared post-run check (see Post-run checks) or dropped from the engine.

Status, 2026-11-03: bootstrap v53 does the first three. Trust, the hardware and display facts and the game identity move to the engine store, with a trust mirror left in machine notes for older copies. `status` and `visual_verification` are split, so the session status and the display check finding now go to the location record. The transaction marker lives in the location record, written through `--internal-location-set`. The fourth, the target display records the session-end display check reads, waits for the post-run checks.

### Engine-owned store

- The engine-owned store lives under LocalAppData, laid out like Claude Code's per-project memory: one machine-wide engine file, plus one folder per location under a locations directory. From v60 it also holds `engine\mission-ancestors\`, one file per published mission an edit replaced, which never travels with a copy; a merge compares against it, and the Stores view lists, opens and clears it.
- A location folder is named by a readable encoding of the location's path in the style of Claude Code's project folders, plus a short hash of the exact full path, since the readable encoding alone can map two paths to one folder.
- The machine-wide file takes the bootstrap lock. Each location file takes a mutex named from its folder, so sessions at two locations do not contend. When both are needed, the bootstrap lock is taken first, as today's notes writes require.
- No engine state is written into a location's directory outside the .cmd, except where that directory is itself the engine's state root under LocalAppData, as the AppData copy's directory is today.
- The menu can open the machine-wide file and this location's file but never clear them. A location folder whose directory no longer exists is listed as orphaned and is removed only explicitly.

Status, 2026-11-03: the engine-owned store and the move of the engine-owned keys and shared keys' engine parts (trust, hardware and display facts, game identity, session status and the transaction marker) shipped in bootstrap v53 (gist revision `2a1a578e9d1bc4e41c883334b269d28234e54840`), the first of two releases of the Stores slice; the second makes the notes optional slots, adds the free-form format and the post-run checks, which also take over the engine's reading of the agent's target display records. Since no mission helper mechanism exists yet, the post-run display check becomes a built-in named check that `PROJECT.json` declares (user decision, 2026-11-03). The game fingerprint stays in the game notes as an engine-owned origin stamp as well as in the location record, so notes moved into another directory are still caught (user decision, 2026-11-03).

The display check is the first case and becomes a post-run check of the DLSS mission. A mission with no stores therefore keeps trust, the wrong-directory guard and transaction recovery, and clearing a mission store never touches them.

## Post-run checks

- A post-run check is a mission-declared helper with a verify path, which the engine runs at the end of every Execute that is neither a task nor a diagnosis-only session, agent-driven or scripted, and of every scenario run (user decision, 2026-11-09). Until mission helpers exist, the one check is the built-in `display-targets`.
- A failed check makes the run unsuccessful, so disarm-after-success does not fire.
- The check's finding is recorded in the engine-owned store, in the location record (user decision, 2026-11-09).
- From v64 the agent can run the session end's read of the target store (for another mission, its free-form store check) and the same declared checks mid-session, without writing anything, through `--internal-notes-validate` on a trusted game copy, which reports pass, finding or damage; from v65, for a dlss5 mission that declares the target store, a game folder with no game notes file gets the outcome missing instead of damage, since a session started with a task, a diagnosis-only one included, never creates them. The DLSS mission requires that check after every game-notes write and before its final completion report.

## Session transcripts

- A project-config option, off by default, records a session transcript of every command the agent and the helpers run, together with its full output, during Execute and test runs. A second switch in the same option covers authoring sessions. The transcript is written to a declared location.
- The transcript may capture secrets printed by commands, so it is never part of mission content, and it is embedded in the package only by an explicit Pack up (see Pack up).
- A transcript records its origin location (machine and directory).

## Pack up

- A Pack up menu item moves context into the .cmd for transport, as cargo. It lists the packable context, meaning the location's stores (target-directory notes and the location's transcripts) and the machine's stores (machine notes and project knowledge), and the user picks what to pack. Picking a machine store warns that moving it removes it from every location on that machine.
- Pack up is also offered at the end of a run, so the user does not forget before copying the file back to dev.
- Pack up builds on the move of keys that are not mission memory (see Keys that are not mission memory), since until then the notes files still hold engine-owned keys.
- **Cargo:** packed context embedded in its own section outside the hashed mission content, like arm state and test records. Packing therefore never disarms the package and never invalidates test records.
- The menu header shows when cargo is present and its origin location.
- Transcripts are packed only after a warning that the .cmd will carry them, secrets included, to wherever it is copied. There is no secret scan yet.
- Pack up removes the packed files from their locations once the cargo is verified, so the context lives only in the cargo until it is unpacked and cannot drift. A packed store starts empty at its location until the cargo is restored there.
- An Unpack menu item lets the user pick, for each packed item, between restoring it into its store, offered only at the item's origin (the origin location for a location store, the origin machine for a machine store), and importing it as reference material into a folder under LocalAppData named for its origin location, which Distill can pick from. An import never merges into the local stores. Unpack strips the cargo from the .cmd once every write is verified.
- Every auto-update, whole-file or engine-only, re-embeds the cargo section into the new file, so an update never discards packed context.

## Distillation

- A further menu item hands a recorded transcript to the AI in an authoring role, after warning that the transcript, secrets included, goes to the AI host. The agent distills it into deterministic helper scripts with declared preconditions, and parameters in place of machine- or location-specific values, rather than a literal replay.
- Distill defaults to this location's transcript and accepts any transcript file the user picks, including one recorded at a target and brought to dev by Pack up or by hand. The secrets warning names the transcript's recorded origin.
- Distilling only the repeatable parts of a session is expected and still worthwhile, with the rest left to the agent.
- Distilled helpers must carry no captured output or secrets, only the commands' shape with values parameterized.
- The result lands in the exploded files. The user reviews them there before the engine absorbs them as in New mission, and they go through the same absorb, test and arm path.
- A partly distilled mission stays in agent mode with the new helpers available to the agent.

## Scripted execution and export

- A mission declares the scripted execution mode to assert that its helpers cover the whole run, however they were authored. In that mode Execute, and a scenario run alike, runs the helpers without an agent and falls back to the agent only on a failed precondition, step or post-run check.
- The post-run checks run once more when the fallback agent finishes, and that final result decides the run without a second fallback.
- When the mission declares the scripted execution mode, an Export standalone script menu item is offered only while the Arm gate is satisfied (for a mission with no required tests, only while armed). It writes the helpers plus a small runner into a self-contained .ps1 that needs neither the bootstrapper nor an AI host.
- The runner keeps the preconditions, the target assertion and the post-run checks inline as pass or fail steps.
- The export lives outside the engine, so it carries no arm gate, trust, test records, memory stores or auto-update, and later changes to the mission in the .cmd do not reach it. The export is a release, not a live mirror.

## Repository home

- Once implemented, development moves from gists to two Git repositories.
- The builder repository holds the engine, and builds the universal base .cmd from it with the hello-world mission.
- A separate DLSS5-Bot repository uses the engine from the builder repository and keeps the DLSS 5 mission content as loose components (MISSION.md, helpers, tests, project config) in the layout Explode writes.
- The single-file design still holds for what users run: the DLSS 5 package is one self-contained .cmd made from that engine and those components.
- Each repository keeps its backlog in Git beside its source, which also aids discoverability.
- The builder repository, named Pluri-Bot (user decision, 2026-11-20, renamed 2026-11-21 so that descendants can take the Foo-Bot form), holds the engine in exploded, split form: a batch wrapper and `payload.ps1` joined at build time into the engine file, plus the hello-world mission as loose files, from which the hello-world base is built.
- DLSS5-Bot commits a vendored copy of the engine file plus a pin file recording the engine version, the Pluri-Bot commit and tag, and the engine hash. An update script fetches a chosen Pluri-Bot release, verifies its hash and rewrites both files, so an engine update is one reviewable commit. There are no submodules, and the build works offline.
- Automation assembles the package through the engine's own assembly entry point, which embeds the mission with an empty STATE section in published form (not absorb, which writes edit state), and publishes it disarmed. Each machine arms on first use, so every copy needs a manual arm after each update.
- A package is identified by the pair `v<engine>-<mission>`, each half's number owned by its own repository, starting a new version line at v1-1 (the earlier v1 to v67 become legacy versions), with a prime marking an edited mission or an engine that is not a release's (a dev build, or a local engine change, which stays possible without a release and is offered each newer release through Take or Keep); copies update to the latest release as a whole, ordered by the pair, since neither half ever goes backwards across releases (user decisions, 2026-11-21; [spec](../../docs/repository-home/2026-11-20-repository-home-design.md)).
- Published packages and auto-update move to GitHub Releases of DLSS5-Bot: automation attaches the .cmd and its SHA-256 to a tagged release, and auto-update reads the latest release. No gist bridge is published: the author switches each copy to v1-1 by hand, v1 starts a fresh trust store, and the gist stays frozen at legacy v67 with its README replaced by a pointer at the releases (user decisions, 2026-11-21).
- From v1-1 the product carries its repository's name: the package file is `DLSS5-Bot.cmd`, each mission's `PROJECT.json` declaring the file name the engine enforces (`Pluri-Bot.cmd` for the hello-world base), the game notes become `DLSS5-Bot.md`, renamed by the user when a session refuses an old name, as the existing legacy notes rule does today, and the engine keeps its state, shared by every mission, in `%LOCALAPPDATA%\Pluri-Bot`, with the DLSS stores at its root as today; the mission id stays `dlss5`, and the old `%LOCALAPPDATA%\DLSS5-ADDER` folder becomes the archive (user decisions, 2026-11-21).
- Until the repositories exist, the whole backlog stays here. At migration each entry goes where its code lives, engine work to the builder repository and mission work to DLSS5-Bot; an entry that spans both goes to the builder repository, with a pointer entry in DLSS5-Bot.
- Both repositories are cloned outside LocalAppData, for example under C:/Git. LocalAppData holds only runtime state, apart from the frozen `development\` archive, which stays in the old folder, and the local `release-records\` folder, which moves with the runtime state (user decisions, 2026-11-21), and is never a clone. Each repository's .gitignore still covers exploded files, build output and test scratch.

## MVP scope

- The engine and the mission content are split behind clear markers, with the mission hash over the mission content, and trust is keyed to the engine hash alone.
- The base .cmd ships the hello-world mission. The DLSS mission is repackaged as mission content, with today's three notes files kept as fixed stores.
- The menu opens on double-click and offers Arm, Execute and Explode; a drop runs absorb with its verification and its secret-pattern warning. The header shows the arm state and the mission hash, and internal arguments let engine tests drive the menu and absorb headless.
- Arming is minimal: a package starts disarmed and arms after one explicit confirmation, the no-required-tests path; every mission content write disarms it. A minimal embedded project config holds the rerun setting.
- Today's whole-file auto-update and gist publishing continue, but copies are identified and reconciled by version plus engine hash instead of a hash of the whole file, so arm state and mission edits do not conflict with the canonical copy.
- The machine's single canonical slot holds the DLSS package only; hello-world exists only as the base file.
- Status, 2026-10-31: the MVP shipped as bootstrap v50, built in `development/v50-composable-mvp/` under the spec `development/2026-10-25-v50-composable-mvp-design.md`, installed as the canonical AppData copy and published to the gist at revision `422d93e3c7e7c5007874e514ede2a901679bce2a` (SHA-256 `a64f160ea946799b7d94f262625af63d4854a174d7d931d0c0327b29cd34508b`). Its settled decisions: the canonical slot holds only the clean published DLSS package (making that apparent to users is deferred); a whole-file update replaces an absorbed mission edit, keeping the previous file as `.bkp`, and arrives disarmed behind a what's-changed box offering Accept and re-arm or Keep disarmed; the DLSS mission arms by confirmation with no required tests and reruns while armed; letters and the arrow keys move the menu highlight, only Enter acts on a choice, and Esc quits or cancels; dropping onto the open window and removing a mission file are deferred to their own slices.

## Open questions

- Assumed, to be confirmed: Pack up never packs the engine-owned store, since moving trust or a transaction recovery marker away from its location would be unsafe.
- Settled for the MVP: the DLSS mission arms by confirmation with no required tests. Settled for the Tests and Arm gate slice (user decision, 2026-11-07): it keeps arming by confirmation with no required tests, since it has no tests to require yet.
- How several different packages share one machine, since the MVP's single canonical slot holds the DLSS package only.
- Settled for the MVP: the canonical slot only ever receives the clean published DLSS package, so a copy's arm state, mission edit or other mission never reaches it. Open for later slices: what the slot holds now that copies carry test records (from v55, though the slot still receives only the published package, whose STATE is empty) and once they carry cargo, or several packages share one machine; the statements that every update arrives disarmed and that an update re-embeds the receiving copy's cargo depend on the answer.
- Settled for the MVP: a whole-file update replaces a copy's absorbed mission edit, keeping the previous file as `.bkp`. Settled for the Tests and Arm gate slice (user decision, 2026-11-07): a whole-file update keeps the copy's test records, which name their mission hash, so a changed mission's records simply stop matching; the update still arrives disarmed.
- Settled for the engine-owned store (spec `development/v53-engine-store/2026-11-03-v53-engine-store-design.md`): trust is read from the union of the engine file and machine notes, every trust write goes to the engine file and is mirrored into machine notes for older copies, and each launch reconciles the two; an in-flight transaction marker is copied into the location record and removed from game notes in one migration sequence, with a conflict refusing the session; every multi-write migration has defined crash states. Whole-file and engine trust entries both move this way.
- Settled for the engine-owned store: the location path is the folder's final path (junctions resolved), its record is found by a case-insensitive hash of that path, a case-only rename keeps the record, and a session at a moved directory takes over the orphaned record when exactly one matches its folder token and fingerprint; otherwise the orphan stays listed in the menu with its marker. SUBST and mapped drive letters can give one directory two records, which is accepted.
- Pack up and Unpack states still to define: Pack up while cargo from the same or another location is already present; what verifying the cargo means (absorb's equivalent re-explodes to scratch and compares); a partial removal after packing, and an Unpack that writes but fails to strip, with rerun behavior for each; an existing import folder for that origin, and whether it uses the engine-owned store's folder naming; restoring into a store that has changed since it was packed; a session running at the location during Pack up, since target-directory notes take no lock; and what the copy of the .cmd left at the target does with its cargo once the file is copied to dev.
- Settled for the Mission file removal slice (user decision, 2026-11-08; spec `development/v56-mission-file-removal/2026-11-08-v56-mission-file-removal-design.md`): v55 left no route to remove an embedded test, since absorb only adds or replaces files and a dropped `PROJECT.json` without the declaration fails the check that every test file is declared. Bootstrap v56 adds the menu's Remove mission files item and `--internal-remove`, which remove instruction and test files in one mission content write, each removed test's declaration with it; `MISSION.md` and `PROJECT.json` are never removed, the seed keeps Configure's Remove seed as its one route, and an instruction file the template still names is refused rather than edited out of the template. Status, 2026-11-08: the slice shipped as bootstrap v56, installed as the canonical AppData copy and published to the gist at revision `d519d79e1cf92ffc8bb390652203b04371184539` (SHA-256 `0a5825582aa8dc3ca84442de9351025ebf091b9b0ffb585da893591758c1e747`).
- To revisit after the MVP ships (review notes, 2026-10-23): whether .cmd self-writes under the bootstrap lock stay as recorded; the no-engine-state rule's scope beyond target directories and the self-replacement's candidate and rollback files beside the .cmd; the two senses of location and transcript cardinality; per-copy wording of first-use arming; splitting export from scripted execution so only export needs the Tests and Arm gate slice; slice ownership of the store-path list and the declared target in the header; cargo in the identifying-data notice; per-item cargo origin metadata and restoring into an undeclared store; and recording each location folder's exact path for orphan detection.

## Related

- Connected to [Restricted agent capability boundary](restricted-agent-capability-boundary.md).
- Connected to [Offer AI host install](offer-ai-host-install.md).
- Connected to [Non-interactive mode](non-interactive-mode.md).

Captured 2026-10-21, expanded 2026-10-23. Repository home captured 2026-10-23. Earlier open questions settled, Pack up added and the MVP cut on 2026-10-23, with trust expectations softened for personal use.
