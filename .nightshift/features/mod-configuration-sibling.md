---
status: exploring
---

# Mod configuration sibling

A sibling mission to DLSS5-Bot (formerly DLSS5-ADDER) for general mod configuration (user idea, 2026-11-21). It reads the DLSS notes (machine notes and game notes) but never writes them, checks a planned mod install against what a game folder already holds, refuses incompatible combinations (for example installing the GTA IV DXVK port over RTX Remix in Grand Theft Auto IV), and resolves the conflicts it finds where it can. Connected to the [Composable AI bootstrap builder](composable-bootstrap-builder.md), whose engine and declared stores would carry it as another mission, and to its Repository home slice, which decides where a second mission lives. Open questions: whether it is a mission of its own (with its own `mission_id`, stores and repository) or a mode of the DLSS mission; how it reads another mission's stores read-only, since `PROJECT.json` today declares only a mission's own stores; where its compatibility knowledge lives (a store of its own, a curated rules file, or the agent's research per session); what "resolve" may do without confirmation, given the cleanup and transaction rules the DLSS mission keeps; and how it shares the single-instance guard and the game-folder transaction marker with a DLSS session on the same folder. Captured 2026-11-21.
