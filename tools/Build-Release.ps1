param([string]$OutputDirectory = (Join-Path $PSScriptRoot '..\build'))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Builds a Pluri-Bot release's files: the engine file, joined from the wrapper and payload.ps1, and the hello-world base, assembled from the engine file
# with the hello-world mission, each with a .sha256 file. The base must carry exactly the engine it was assembled from, in published form.
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$null = New-Item -ItemType Directory -Force -Path $OutputDirectory
$engine = Join-Path $OutputDirectory 'engine.cmd'
& (Join-Path $PSScriptRoot 'Join-Engine.ps1') -Output $engine
# Legacy v67 runs a package only under the name DLSS5-ADDER.cmd, so the base keeps it until the engine declares names per mission.
$base = Join-Path $OutputDirectory 'DLSS5-ADDER.cmd'
[IO.File]::WriteAllBytes($base, [IO.File]::ReadAllBytes($engine))
$null = & (Join-Path $PSScriptRoot 'Assemble-Package.ps1') -Package $base -Mission (Join-Path $repository 'missions\hello-world')
. ([scriptblock]::Create((& (Join-Path $PSScriptRoot 'Get-PayloadDefinitions.ps1') -Path $engine))) -SelfPath $engine
$engineSha256 = [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($engine)))
$baseIdentity = Get-Dlss5BootstrapIdentity -Bytes ([IO.File]::ReadAllBytes($base)) -Strict
if ($baseIdentity.EngineSha256 -cne $engineSha256) { throw "The base engine $($baseIdentity.EngineSha256) differs from the engine file $engineSha256." }
if ($baseIdentity.Sha256 -cne $baseIdentity.PublishedSha256 -or $baseIdentity.MissionId -cne 'hello-world') { throw 'The base is not a published hello-world package.' }
$utf8 = [Text.UTF8Encoding]::new($false)
foreach ($file in @(@($engine, $engineSha256), @($base, $baseIdentity.Sha256))) {
    [IO.File]::WriteAllText($file[0] + '.sha256', $file[1] + '  ' + [IO.Path]::GetFileName($file[0]) + "`n", $utf8)
}
"engine version $($baseIdentity.Version) sha256 $engineSha256"
"base sha256 $($baseIdentity.Sha256)"
