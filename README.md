# Pluri-Bot

Pluri-Bot is the engine of a composable AI bootstrap for Windows: one self-contained `.cmd` file that carries a shared engine and the mission of one task, launches Claude Code or Codex CLI with that mission's prompt, and keeps the package's trust, tests, stores and updates. A mission is a small set of files (a `MISSION.md` prompt template, a `PROJECT.json` and optional instruction and test files), so a new task needs no engine changes.

This repository holds the engine source and the hello-world mission, from which each release builds:

- `engine.cmd`, the engine file, a package with no mission, whose SHA-256 is the engine hash of every package built from it;
- `DLSS5-ADDER.cmd`, the hello-world base, a harmless starting package for a new mission.

[DLSS5-Bot](https://github.com/astenlund/DLSS5-Bot), the DLSS 5 mission, vendors this engine. Descendants may take the Foo-Bot form.

The current engine is the imported legacy v67 engine, released as `legacy-v67`. A new version line starts at v1. See `AGENTS.md` for the layout and the working rules, and `docs/repository-home/` for the design of this repository's creation.
