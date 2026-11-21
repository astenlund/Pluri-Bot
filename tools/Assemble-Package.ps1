param([Parameter(Mandatory)][string]$Package, [Parameter(Mandatory)][string]$Mission)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Embeds a mission folder into a package as its MISSION section with an empty STATE section, using the package's own section functions,
# so the release files ship in published form. The first run also removes v49's base64 instruction assignments from the payload.
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$newline = [string][char]13 + [char]10
$text = [IO.File]::ReadAllText($Package, $utf8)
$lines = [Collections.Generic.List[string]]::new([string[]]$text.Split($newline, [StringSplitOptions]::None))
foreach ($name in @('LocalRuntimeBuild', 'BootstrapChange', 'Optimization', 'Cleanup')) {
    $prefix = '$script:Dlss5' + $name + 'Instructions = '
    $index = $lines.FindIndex([Predicate[string]]{ param($line) $line.StartsWith($prefix, [StringComparison]::Ordinal) })
    if ($index -lt 0) { continue }
    if ($lines[$index + 1].Length -ne 0) { throw "Expected a blank line after $prefix" }
    $lines.RemoveRange($index, 2)
}
$begin = $lines.IndexOf('### === POWERSHELL_PAYLOAD_' + 'BEGIN ===')
$close = -1
for ($index = 1; $index -lt $begin; $index++) { if ($lines[$index] -ceq ')') { $close = $index; break } }
if ($close -lt 0) { throw 'The batch block closing line was not found.' }
$prefix = '### === DLSS5_' + 'SECTION_'
if ($begin -eq $close + 1) {
    $lines.InsertRange($begin, [string[]]@(($prefix + 'MISSION_BEGIN ==='), ($prefix + 'MISSION_END ==='), ($prefix + 'STATE_BEGIN ==='), ($prefix + 'STATE_END ===')))
}
$bytes = $utf8.GetBytes([string]::Join($newline, $lines))

. ([scriptblock]::Create((& (Join-Path $PSScriptRoot 'Get-PayloadDefinitions.ps1') -Path $Package))) -SelfPath $Package
$files = [ordered]@{}
foreach ($file in @(Get-ChildItem -LiteralPath $Mission -File)) { $files[$file.Name] = [IO.File]::ReadAllBytes($file.FullName) }
$bytes = Set-Dlss5PackageSections -Bytes $bytes -Bodies ([ordered]@{ MISSION = (ConvertTo-Dlss5MissionBody $files); STATE = [string[]]@() })
$identity = Get-Dlss5BootstrapIdentity -Bytes $bytes -Strict
[IO.File]::WriteAllBytes($Package, $bytes)
'{0} version {1} mission {2} engine {3} mission_sha256 {4}' -f $Package, $identity.Version, $identity.MissionId, $identity.EngineSha256, $identity.MissionSha256
