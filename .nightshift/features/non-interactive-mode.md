# Non-interactive mode

Add a launch mode in which the agent does its best to complete the task without user interaction: it makes the decisions it would otherwise ask about, and where a step cannot proceed without the user it records why and moves on or stops. Connected to [Composable AI bootstrap builder](composable-bootstrap-builder.md), whose approval mode (default, manual or auto; an allowlist is deferred) and scripted execution mode are adjacent, to [Offer AI host install](offer-ai-host-install.md), and to [Mistral Vibe host](mistral-vibe-host.md).

## Settled design

- Session shape: the host keeps its interactive session with a no-prompt permission mode, so the console stays visible, someone can watch or step in, and the final report appears there. Claude Code launches with `--permission-mode dontAsk`, which denies any tool not pre-approved instead of prompting; Codex launches the interactive `codex` command with `--ask-for-approval never`, which returns failures to the model instead of asking, together with a `--sandbox` policy. Headless runs (`claude --print`, `codex exec`) are not used. Codex's approval-bypassing flag is not used.
- Confirmations nobody can give: when an operating rule requires the user's confirmation (installing software, changing global Git configuration, a game-file change the rules gate on approval), the agent skips that step, records why in the session report, and continues with work that does not depend on it; dependent work stays undone. Skipping is the only fallback; the mode never treats silence as approval.
- Selection: a package configuration setting, part of the builder's approval mode in project config, so an armed package carries it; an internal argument selects it for tests. There is no user-facing launch argument, environment variable or separate menu item.
- Applies to every mission, DLSS game sessions included. A DLSS session run this way records visual verification and any display check needing a person as pending rather than passed, and its report says so.
- Report: the session ends with what it did, what it decided on the user's behalf, and what it skipped or left undone, with the reason for each.

## Open questions

- Which tools to pre-approve for `dontAsk`, per mission, so the agent can still do useful work, and where that list lives (mission content, or a later allowlist approval mode, which v51 deferred because Claude Code's `--allowedTools` only adds to the user's own allow rules).
- Which `--sandbox` policy Codex uses, and whether it differs per mission.
- How the operating prompt tells the agent it is in this mode, and how each rule that asks the user is rewritten for it.
- How pending visual verification from an unattended DLSS session is surfaced at the next attended launch.

Captured 2026-10-25. Graduated 2026-11-01 with the session-shape, confirmation, selection, scope and report decisions above.
