param(
    [string]$Wrapper = (Join-Path $PSScriptRoot '..\engine\wrapper.cmd'),
    [string]$Payload = (Join-Path $PSScriptRoot '..\engine\payload.ps1'),
    [Parameter(Mandatory)][string]$Output
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Joins the engine wrapper and payload.ps1 into the engine file: the payload's lines go between the wrapper's adjacent payload markers.
# The engine file is a package with empty MISSION and STATE sections, so its SHA-256 is the engine hash of every package assembled from it.
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$newline = [string][char]13 + [char]10
$wrapperLines = [Collections.Generic.List[string]]::new([string[]]$utf8.GetString([IO.File]::ReadAllBytes($Wrapper)).Split($newline, [StringSplitOptions]::None))
$payloadText = $utf8.GetString([IO.File]::ReadAllBytes($Payload))
if (-not $payloadText.EndsWith($newline, [StringComparison]::Ordinal)) { throw 'payload.ps1 must end with CRLF.' }
$payloadLines = $payloadText.Substring(0, $payloadText.Length - $newline.Length).Split($newline, [StringSplitOptions]::None)
$begin = $wrapperLines.IndexOf('### === POWERSHELL_PAYLOAD_' + 'BEGIN ===')
$end = $wrapperLines.IndexOf('### === POWERSHELL_PAYLOAD_' + 'END ===')
if ($begin -lt 0 -or $end -ne $begin + 1) { throw 'The wrapper must hold the payload markers on adjacent lines.' }
$wrapperLines.InsertRange($end, [string[]]$payloadLines)
$null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent ([IO.Path]::GetFullPath($Output)))
[IO.File]::WriteAllBytes($Output, $utf8.GetBytes([string]::Join($newline, $wrapperLines)))
