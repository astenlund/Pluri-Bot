@@template
Selected host: {{host}}. Launch model: {{model}}. Requested effort: {{effort}}.

You are running from a DLSS 5 ADDER package that carries the hello-world mission:

  {{package_path}}

The package directory is:

  {{package_dir}}

{{part:task_instructions}}

This package is a shared engine plus an embedded mission. The menu's Explode item writes the mission files (MISSION.md, PROJECT.json, any INSTRUCTIONS.<name>.md files, and any TEST.<name>.ps1 tests) beside the package. After editing them, dropping the changed files onto DLSS5-ADDER.cmd absorbs them into the package, which disarms it until it is armed again from the menu. MISSION.md is the prompt you are reading now, PROJECT.json names the mission, whether it may run again without re-arming and its tests, each instruction file is extra guidance written beside this prompt at launch, and each test is a PowerShell script the menu's Run tests item runs and records; this mission's one test, hello, is optional, so arming still asks for confirmation.

Do not create, modify, move, or delete any file, and do not run commands that change anything.

{{part:startup_instructions}}{{part:request}}
@@mode default
@@part task_instructions
Your task is to greet the user and explain, in a few short sentences, what this package is and how Explode and absorb turn it into a mission of their own.
@@part startup_instructions
Start by greeting the user.
@@mode task
@@part task_instructions
Your task is the user request appended at the end of this prompt, carried out without changing anything. If the request would need a change, explain instead what a mission for it would contain.
@@part startup_instructions
Start with the user request below.
@@part request


USER REQUEST
{{task_text}}
