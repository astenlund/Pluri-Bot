# Import record

Pluri-Bot's initial commits import the engine of DLSS5-ADDER at legacy v67, the last release published from its gist, as the repository-home design (`docs/repository-home/2026-11-20-repository-home-design.md`) sets out. The history of the legacy line (v1 to v67) is not reconstructed as commits; its development folders stay in the author's LocalAppData as a frozen archive. DLSS5-Bot's own import record covers the DLSS mission's half.

## Sources and hashes

- The engine source comes from the published legacy v67 package, `DLSS5-ADDER.cmd`, SHA-256 `35414382fc84514ea47197d5bdb2d01f158b33ecf6d6b8c854cfd3ee99a92140`, published at revision `858ae4c6efe62fc2180eb5f040f8e7e2697668ec` of gist `b05c26b341d569124bcdd0edf29c34cf`. Removing the bodies of its `MISSION` and `STATE` sections gives the engine file; `engine/wrapper.cmd` is that file without the payload's lines, and `engine/payload.ps1` holds exactly those lines.
- `tools/Join-Engine.ps1` joins them into an engine file whose SHA-256, `2701fafcded1e2ed1a206c7eaf4b925186922a12675be3eee2f0492d2e747ef4`, equals the engine hash of the published legacy v67 package as its `Get-Dlss5BootstrapIdentity` computes it.
- The hello-world mission comes from the legacy v67 release folder's `mission-hello-world\`. The legacy v67 hello-world base, the release folder's `base\DLSS5-ADDER.cmd`, has SHA-256 `28d05a2c794061c95b0027b18b4deed5fe38fcbd9ec8d05f59801073183925fc`, captured from the archive before the import; `tools/Build-Release.ps1` assembles a byte-identical base from the joined engine and `missions/hello-world/`.
- `tools/Assemble-Package.ps1` and `tools/Get-PayloadDefinitions.ps1` are the legacy v67 release folder's files, unchanged. `tools/Invoke-SuiteOffscreen.ps1` is unchanged, and `tools/Invoke-SuiteToFile.ps1` differs only in its default suite, which names this repository's test instead of a path on the author's machine.

## Tests

- `tests/Test-HelloBase.ps1` is the legacy v67 release folder's hello base test, with its default base path, its scratch folder name and its definitions loader pointed at this repository's layout.
- `tests/Test-PluriBotBase.ps1` holds the release-suite cases that read the hello-world base, moved here from DLSS5-ADDER's release suite by the user's decision of 2026-11-21: "package hello-world base shares the engine and runs as a plain mission" and "guard holds the hello-world base folder too", each unchanged apart from reading the base, the engine file and the hello-world mission from this repository, and the base variant of "store menu lists the engine store and removes orphaned, unreadable, mismatched and collision records on confirmation" as its own case, "store menu of the hello-world base lists the engine file and the removable records, but no record of its own". The helper functions it needs, the case runner and its filter included, are copied unchanged from that suite; `tests/Hold-DLSS5Guard.ps1` is unchanged. All three cases pass against the built base through the off-screen runner.

## Backlog

The backlog moves here from the LocalAppData folder's `.nightshift\`, apart from the DLSS release procedure entries ("Release suite in CI" and "Lighter post-review gate"), which go to DLSS5-Bot. The history indexes, the bug records and every feature record other than those two stay together here, so their links still resolve; DLSS5-Bot's backlog points here for the entries that span the engine and its mission. Each moved file that names a `development/` path carries a note marking those paths as the local archive. Once step 1 acceptance passes, the LocalAppData backlog is reduced to a pointer at the two repositories.

## Privacy sweep

`tools/Invoke-PrivacySweep.ps1` swept every commit of the import, each commit's message and every file it adds or changes, before the first push, and reruns over the outgoing commit range before every push. Its generic patterns are a home folder path other than a fixture name, an email address outside the reserved example domains, and GitHub, Anthropic and AWS token shapes and private key headers. Its literal terms (the author's names, account, computer name and machine id) and the values public by the author's decision (the commit address) are kept outside the repository, in the LocalAppData `release-records\` folder. The import's sweep found no hits in this repository once the terms matched whole words only, so the GitHub owner name in URLs no longer matched a shorter term.
