# Features

Paths under `development/` in this file name the frozen local archive in the LocalAppData folder the project came from; they are not part of this repository.

Product-level feature ideas captured during brainstorming. Each entry points at a standalone file under `.nightshift/features/<slug>.md` with the full design sketch. Check this index before proposing new feature directions in the same territory.

This file is **one of four repo-local indexes** agents consult on demand when relevant (alongside `QUICK_WINS.md`, `BUGS.md`, `PATTERNS.md`). Each entry here is a short paragraph summary plus a `**Requires:**` line, an optional `**External:**` line, and optionally a `**Slices:**` block (formal MVP plus continuations; see `## Slicing` below). For features that are partially done without a formal slice breakdown, describe the partial progress in the entry's own prose: there is no separate marker convention for "partially shipped". The detailed design lives in the linked file. When a feature (or a slice of a sliced feature) ships, append its entry to [`FEATURES_HISTORY.md`](FEATURES_HISTORY.md); do not keep an `## Implemented` section inline.

Readiness and graduation are not approval. Agree meaningful commitments through an investigated understanding readback or concise spec; preserve valid agreement through compatible corrections and compaction.

Backlog prose is one paragraph or one bullet per physical line, never hard-wrapped at a column: a search hit then shows the whole entry, the parsers anchor on whole lines, and an edit shows as one changed line instead of a reflowed block. `/nightshift:ready` reports a hard-wrapped file as a notice so it can receive a scoped repair before handover.

## Requires lines

**Every feature index entry carries a `**Requires:**` line** declaring the upstream gates that block the feature. The line is comma-separated and stays on one physical line (the parser joins a wrapped line, but the line discipline above forbids wrapping). Each item is one of two forms:

- A markdown link to a feature, quick win, or bug entry tracked in one of the four indexes. The reference is a current blocker; under the walk-and-remove convention below, a satisfied dependency is edited out of the line at the moment it ships, so `/nightshift:ready` treats every in-backlog reference as actively blocking.
- The literal word `none.` if there are no upstream gates. An empty label is a structural error; `none.` is the only empty form.

Bare text in `**Requires:**` is a structural error. External primitives (an SDK feature, infrastructure capability, library, hardware, a user decision) go on a separate, optional `**External:**` line directly below it, with the same comma-separated grammar: `**External:** vendor SDK 3.0, hardware enclosure.` Absence is its only empty form, so `none.`, an empty label, or a markdown link in it is a structural error (a link parked there would be invisible to the walk-and-remove convention). A link means an item that is entirely a markdown link; prose that merely contains a link is bare text. `/nightshift:ready` classifies a work unit with at least one in-backlog blocker as Blocked with its externals noted parenthetically, and a work unit with externals and no blocker as External. Every structural error names its remedy.

A missing `Requires:` line is a structural error: every entry must say something. Silence is not the same as `none.`; it indicates the dependency review hasn't been done. The `/nightshift:ready` skill parses these lines to compute the unblocked work set.

**After adding a new entry (or a feature breakout file), and after graduating a draft from `## Exploring`, run `/nightshift:ready`** from the repo root so the bundled `skills/ready/ready.js` validates the post-edit backlog. A new entry must parse and its `**Requires:**` line must resolve. A graduation is incomplete until the selected entry is absent from `exploring`, the selected entry or its unshipped slice work units appear in `ready`, `blocked`, or `external`, the selected entry has no structural error or notice, and the transition introduced no new structural error or notice. Surface pre-existing unrelated problems again, but they do not alone block that graduation. A failed parser invocation, missing work index, missing active classification, selected-entry problem, or newly introduced problem stops graduation until corrected and rechecked.

Downstream relationships (this feature **enables** what) are not encoded structurally. They can be derived by walking the upstream graph in reverse, and over-codifying them creates a second source of truth that drifts. Mention downstream relationships in design prose where they aid understanding.

**Carve-outs:** sections like `## Working hypotheses`, `## Staging`, `## Future directions (not yet designed)`, `## Author tooling`, and `## Exploring` describe pre-feature material (orienting prose, shipping order, shallow placeholders, workflow notes, exploratory brainstorms) rather than ready-to-implement entries. Items in those sections do not carry `Requires:` lines (or, in `## Exploring`'s case, may carry them as historical artifacts only). `/nightshift:ready` ignores the bulleted sections entirely and keeps `## Exploring` out of the readiness set, reporting every draft in a separate list with a linked title and brief context; `/nightshift:exploring` renders them in full. Working hypotheses / Staging / Future directions (not yet designed) / Author tooling are bulleted rather than `###` headings, so the `###`-only candidate filter handles them naturally; `## Exploring` holds `###` entries, collected as drafts and never classified.

Concrete entry shape inside the index. The example shows a feature link, a quick-win link, and an External line to show both lines; a real entry only includes whatever it actually depends on:

```markdown
### [<Feature name>](features/slug.md)

<Short paragraph summary.>

**Requires:** [other-feature](features/other-feature.md), [shared helper extraction](QUICK_WINS.md#shared-helper-extraction).
**External:** some external primitive.
```

**When a feature is implemented**, move its index entry to [`FEATURES_HISTORY.md`](FEATURES_HISTORY.md); drop its `Requires:` and `External:` lines in the move (history entries don't need them). The feature file stays in place as a historical design record.

**Then walk every other `**Requires:**` line in `FEATURES.md` and `BUGS.md`** and remove references to the just-shipped feature: if it was the only item on the line, set the line to `**Requires:** none.`. This keeps `Requires:` lines as a literal record of what is *currently* blocking and means `/nightshift:ready` never needs to consult the history file.

**Partially-implemented features** have two routes. If the shipped and remaining work is scoped clearly enough to name a named MVP plus named continuations, use the formal `**Slices:**` block described in `## Slicing` below; `/nightshift:ready` then expands per-slice work units and downstream features can reference specific slices via the `[Feature: slice-name]` link suffix. If the shipped work is real but not yet sliceable (e.g., one layer landed, remaining layers are a wishlist not a planned breakdown), describe the partial progress in the entry's own prose without any special markers. `/nightshift:ready` treats such entries as the `**Requires:**` line dictates; partial progress is editorial context for the reader, not a machine-readable signal.

## Slicing

Features that bundle multiple shippable layers under one design split into a named **MVP** plus one or more **continuations**. The MVP is the smallest surface that unblocks downstream features whose `Requires:` line points at this feature; continuations layer extensions on top.

A sliced feature entry carries a `**Slices:**` block listing each slice (MVP first, then continuations) with one or two sentences on what each delivers. The entry's `**Requires:**` line reflects the *next-to-ship* slice (initially MVP).

After MVP ships, the MVP entry moves to [`FEATURES_HISTORY.md`](FEATURES_HISTORY.md); the MVP bullet in the parent's `**Slices:**` block is struck through with a pointer to the history file; the parent entry stays in its themed section; the top-level `**Requires:**` and `**External:**` lines advance to the next-to-ship slice's gates; and every other `**Requires:**` line in `FEATURES.md` / `BUGS.md` that referenced the just-shipped slice (bare-link defaults to MVP) is edited to drop the now-satisfied reference. When later continuations have independent gates (they can ship in any order rather than sequentially), each slice bullet may carry inline `**Requires:**` and `**External:**` annotations for documentation. Example shape post-MVP:

````
**Slices:**

- ~~MVP - floating-reference core.~~ (Shipped; see FEATURES_HISTORY.md.)
- **Re-anchor events.** Manual UI re-anchor + `AnchorEvent` plumbing.
- **Late-join replay.** `GetSessionHistory` pull endpoint.
- **`RepertoireChordSource`.** Drop-in replacement consuming chart repertoire.
  **Requires:** [chart-repertoire](features/chart-repertoire.md).

**Requires:** none.
````

Downstream features that need a specific continuation (not just the MVP) encode the slice name in the link's display text:

```
[feature-title: continuation name](features/slug.md)
```

A link without a `: slice-name` suffix resolves to the MVP: the default unblock point.

As each slice ships, append a line to `FEATURES_HISTORY.md`:

```
- [Feature title: slice name](features/slug.md): brief note.
```

The parent entry stays in its themed section until the **last** slice ships, at which point it graduates with the final history line.

`/nightshift:ready` reads the top-level `**Requires:**` and `**External:**` lines and any inline `**Requires:**` and `**External:**` annotations on slice bullets, then reports each unshipped slice as a separate work unit (`[Feature title: slice name]`). A slice is "unshipped" when its bullet in the `**Slices:**` block is *not* struck through; the strikethrough is the live slice-status indicator that `/nightshift:ready` reads. The **first unshipped slice** (top-most non-struck bullet) uses the top-level lines as its gates; other unshipped slices use their inline annotations if present, or have no extra gates if no annotation. All non-MVP slices **implicitly depend on MVP being struck through**, regardless of top-level or inline gates; a continuation is never reported as Ready while MVP is unshipped. A slice may declare an inline `**Requires:**` pointing at another slice of the same feature via the suffixed-link form, useful when one continuation builds directly on another; resolve the reference by checking whether the target slice's bullet is struck through. As each slice ships, append its entry to `FEATURES_HISTORY.md`, strike through its bullet in the parent's `**Slices:**` block, advance the top-level `**Requires:**` and `**External:**` lines to the new next-to-ship slice's gates (dropping `**External:**` when that slice declares none), and walk every other `**Requires:**` line in `FEATURES.md` / `BUGS.md` to drop now-satisfied references.

## Folding fixes into features

A fix that an active feature would make obsolete is carried by that feature instead of becoming a quick win or bug entry; `QUICK_WINS.md` and `BUGS.md` give the rule for when a fix qualifies. The feature's breakout record lists each such fix as one top-level `- ` bullet under a `## Carried fixes` heading, giving the observed failure, its location, what the replacement must do and a link to the evidence; on a sliced feature the bullet begins with the name of the slice whose work removes the fix's lines, as its `**Slices:**` bullet names it, and a colon. A repeat adds a date to that line, never a paragraph. `/nightshift:ready` counts the bullets at column 0 under each level-two ATX `## Carried fixes` heading, up to the next level-one or level-two heading and outside fences and raw HTML, and shows the count beside the feature when it is ready, so carried fixes become a signal for what to build next; on a sliced feature the count covers the whole record and appears beside each ready slice. An Exploring draft carries no fixes, since it has not settled which code it replaces, and ready reports a notice for a draft whose record has any.

A feature's readback or spec covers every carried fix, its acceptance covers every carried fix, and its history entry lists them when it ships. On a sliced feature each slice does this instead for the carried lines that name it, and those lines leave the record when that slice ships; the next slice's readback assigns a slice to any line that names none. A fix can also be split when the feature would remove only part of what it changes: the carried line holds that part and links its evidence rather than the entry that keeps the rest, so either can ship first, and when the feature, or the slice the line names, ships, that entry's pointer to the carried part is removed. When a feature is retired, deferred indefinitely or marked won't fix, each carried fix is triaged again on its own merits: if it still describes a live defect, it rejoins the entry it was split from while that entry is active, or otherwise becomes a quick win or bug entry; if not, it is dropped with a one-line reason in the feature's history entry.

## Exploring

Pre-dependency-analysis brainstorms live here. An entry is a draft feature whose breakout file carries `status: exploring` in its frontmatter; the design is being firmed up and a `**Requires:**` line isn't expected yet. `/nightshift:ready` lists every draft separately with a linked title and brief context in an Exploring section, never in the readiness set, and `/nightshift:exploring` renders the full draft list. When a draft firms up enough to declare its upstream gates, move it out of `## Exploring` into the appropriate themed `##` section, add the `**Requires:**` line, and drop the `status: exploring` frontmatter on the breakout file. The post-edit `/nightshift:ready` gate in `## Requires lines` is part of graduation, not a later cleanup.

### [Restricted agent capability boundary](features/restricted-agent-capability-boundary.md)

Give the agent task-limited read access and a small set of bootstrapper-mediated operation tools, enforcing permitted reads, writes, helper execution and network access outside the prompt.

### [Mistral Vibe host](features/mistral-vibe-host.md)

Support Mistral Vibe as a third AI host beside Claude Code and Codex CLI, in host detection, the interactive choice, `--host`, `--model`, `DLSS5_AGENT_HOST` and the per-host model and effort settings.

### [Mod configuration sibling](features/mod-configuration-sibling.md)

A sibling mission for general mod configuration that reads the DLSS machine and game notes without writing them, refuses incompatible mod combinations (such as GTA IV DXVK over RTX Remix) and resolves conflicts where it can.

## Launch preflight

### [Diagnosis-only recovery sessions](features/diagnosis-only-recovery-sessions.md)

When a startup check fails but the AI host can still launch, start a diagnosis-only session that helps repair the cause while game modifications stay blocked until the check passes. The first case, missing Git under Git metadata, shipped in bootstrap v46 (see FEATURES_HISTORY.md). The second case, repository inspection failing while Git is present, shipped in v48; each further startup failure joins as its own decision.

**Requires:** none.

### [Offer AI host install](features/offer-ai-host-install.md)

When no AI host is installed, offer an attended, per-user install through the vendor's verified route, with sign-in completable on another device via a QR code of the login link, and an offer to remove what was installed when the session ends.

**Requires:** none.

## Bootstrap builder

### [Composable AI bootstrap builder](features/composable-bootstrap-builder.md)

Evolve DLSS5-ADDER into a general menu-driven bootstrap that packages a shared engine with task-specific mission content, with explode and absorb authoring, travelling tests behind an Arm gate, declared memory stores and transcript distillation into scripted helpers. Once implemented, it moves to its own Git repository, with DLSS 5 in a separate repository built on its base file.

**Slices:**

- ~~**MVP.** Engine and mission split with the mission hash, engine-only trust, copies reconciled by version plus engine hash with DLSS as the machine's one package, the hello-world base, the DLSS mission as mission content with fixed notes stores, the double-click menu with Arm, Execute and Explode and a header showing arm state and the mission hash, drop-to-absorb with headless internal arguments, arming by explicit confirmation with a minimal project config holding the rerun setting, and today's whole-file auto-update and gist publishing.~~ (Shipped in bootstrap v50; see FEATURES_HISTORY.md.)
- ~~**Tests and Arm gate.** Travelling tests, test records, location roles, the dev-to-target flow and the identifying-data notice.~~ (Shipped in bootstrap v55; see FEATURES_HISTORY.md.)
- ~~**Engine-owned store.** The engine file and per-location records under LocalAppData, the move of the engine-owned keys (trust, hardware and display facts, game identity, session status and the transaction marker) out of the notes files with automatic migration, the trust mirror in machine notes for older copies, and the write channel for the agent's transaction marker.~~ (Shipped in bootstrap v53; see FEATURES_HISTORY.md.)
- ~~**Stores.** Optional mission memory slots with the free-form Markdown format and generated prompt sections per enabled store, and post-run checks, the display check first as a built-in named check that `PROJECT.json` declares (no mission helper mechanism exists yet), which also takes the engine's own reading of the agent's target display records out of the session core.~~ (Shipped in bootstrap v57; see FEATURES_HISTORY.md.)
- ~~**Configuration.** The machine and project config split, the baked seed, the approval mode and the target assertion.~~ (Shipped in bootstrap v51; see FEATURES_HISTORY.md.)
- **Transcripts and Pack up.** Session transcripts, Pack up and Unpack with their end-of-run offer, and carrying cargo across auto-updates.
  **Requires:** none.
- **Authoring.** New mission, Dev mode and the helper gallery.
- **Distillation.** Distilling recorded transcripts into helpers.
  **Requires:** [Composable AI bootstrap builder: Transcripts and Pack up](features/composable-bootstrap-builder.md), [Composable AI bootstrap builder: Authoring](features/composable-bootstrap-builder.md).
- **Scripted execution and export.** The scripted execution mode with agent fallback, and the standalone script export.
  **Requires:** none.
- ~~**Engine-only auto-update.** Replacing the engine and re-embedding unchanged mission content, keeping test records and disarming, with a changed mission offered separately.~~ (Shipped in bootstrap v59; see FEATURES_HISTORY.md.)
- ~~**AI-assisted mission merge.** When an update brings a changed mission and the copy's own mission has changes of its own, offer an AI-assisted merge of the two beside taking or keeping either one (user idea, 2026-11-11).~~ (Shipped in bootstrap v60; see FEATURES_HISTORY.md.)
- **Repository home.** The two repositories, vendored base pinning, automated assembly, GitHub Releases, the backlog split and clones outside LocalAppData.
- **Transcript scan and scrub.** A secret scan and scrub for packed transcripts, to make packing them (probably) safe.
  **Requires:** [Composable AI bootstrap builder: Transcripts and Pack up](features/composable-bootstrap-builder.md).
- **Drop onto the open window.** Absorbing files dropped onto the open menu window, deferred from the MVP because a probe on 2026-10-25 found that the classic Windows Console Host delivers only one path of a multi-file drop (`development/v50-composable-mvp/probe-window-drop-outcome.md`).
- ~~**Mission file removal.** A route to remove a mission file, since the MVP's absorb can only add or replace files.~~ (Shipped in bootstrap v56; see FEATURES_HISTORY.md.)

**Requires:** none.

## Execution modes

### [Non-interactive mode](features/non-interactive-mode.md)

A package-configured launch mode in which the agent completes the task without asking: the host keeps its visible interactive session with a no-prompt permission mode (`dontAsk` on Claude Code, `--ask-for-approval never` with a sandbox on Codex), steps needing confirmation are skipped with a recorded reason, and DLSS sessions record visual verification as pending.

**Requires:** none.

## (add sections as features emerge)

Nothing captured yet.

## History

Implemented features are archived in [`FEATURES_HISTORY.md`](FEATURES_HISTORY.md), loaded on demand so the active backlog above stays scannable. When a feature (or slice) ships, append its entry there rather than to this file, AND walk every other `**Requires:**` line in `FEATURES.md` / `BUGS.md`: remove the now-satisfied reference (if it was the only one, set the line to `**Requires:** none.`). The active `Requires:` lines describe what is *currently* blocking, so `/nightshift:ready` never has to consult the history file; the dependency graph settles as features ship.
