# Offer AI host install

When neither Claude Code nor Codex CLI is installed, offer to install one instead of stopping with "Install Claude Code or Codex CLI, sign in, then run the launcher again." Motivating case: a support mission on a machine the user does not own or set up, such as a client's PC or a relative's laptop, where the launcher should get from double-click to a running agent without a separate setup trip. Connected to [Composable AI bootstrap builder](composable-bootstrap-builder.md), whose non-DLSS missions make this case common, to [Mistral Vibe host](mistral-vibe-host.md), which would add a third install candidate, and to [Non-interactive mode](non-interactive-mode.md).

## Settled design

- Install route: each host's official per-user install route, without elevation. The exact route per host and its integrity check (a pinned hash or a signature verification) are settled at design time from the vendor's current documentation; the offer refuses, falling back to today's message, when the check cannot be made or fails.
- Missing versus ambiguous: host detection distinguishes no candidate at all from more than one matching `claude` or `codex` command on PATH. Only the missing case offers an install; the ambiguous case gets its own error listing the conflicting paths.
- Unattended launches: no install happens without a person's explicit yes. When nobody can answer the offer (redirected input, or a package in non-interactive mode), the launch stops with today's install-and-sign-in message, since sign-in needs a person anyway.
- Removal: the launcher records what it installed on that machine and, when the mission's session ends there, offers to uninstall it and remove its stored sign-in. It never removes a host it did not install.
- Sign-in: in a support case the person at the machine may have no account of their own and may be directed to use the account of whoever sent them the file. Sign-in therefore supports completing the login on another device: the launcher shows the host's login link (or device code) as a QR code in the console, alongside the plain link, so the user can photograph it and send it to the account owner.

## Open questions

- Whether the offer also applies when an explicitly requested host (`--host` or `DLSS5_AGENT_HOST`) is missing, which currently fails with its own error.
- Which login flows each host offers that can be completed on another device (a device-code flow, or an OAuth link whose callback does not need the local browser), and how the launcher obtains the link or code to render (live-claim: provisional; check each host's current CLI before design).
- How the QR code is rendered in the console (an embedded encoder in the engine, mindful of the published file's 1 MB limit, and block characters the classic Windows Console Host displays), and what the user sees when the console is too small.
- The risk of a remotely completed login: the sender's account and its credentials end up on a machine they do not control, so what the launcher warns about, and whether removal at session end is offered more strongly in that case.
- How the user picks between Claude Code and Codex when installing.
- Whether a mission using the builder's scripted execution mode offers the install up front or only when it falls back to the agent (its exported standalone scripts need no host at all).
- How an installed host fits the trust and auto-update model, and where the record of what was installed lives.

Captured 2026-10-25. Graduated 2026-11-01 with the route, detection, unattended, removal and sign-in decisions above.
