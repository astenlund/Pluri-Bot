param([string]$Base = (Join-Path $PSScriptRoot '..\build\DLSS5-ADDER.cmd'))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Runs the hello-world base's own test headless at a scratch location with an isolated store whose engine trust is already recorded,
# and checks that the pass is recorded and that the base still arms headless without a question. It starts the package without a console window, so it runs directly.
$scratchRoot = Join-Path ([IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'DLSS5-ADDER/test-runs'))) ('hello-base-' + [Guid]::NewGuid().ToString('N'))
$store = Join-Path $scratchRoot 'localappdata'
$folder = Join-Path $scratchRoot 'hello'
$package = Join-Path $folder 'DLSS5-ADDER.cmd'
New-Item -ItemType Directory -Force (Join-Path $store 'DLSS5-ADDER'), $folder | Out-Null
Copy-Item -LiteralPath $Base -Destination $package

function Invoke-Launch([string[]]$Arguments) {
    $info = [Diagnostics.ProcessStartInfo]::new('cmd.exe')
    foreach ($argument in @('/d', '/c', $package) + $Arguments) { $info.ArgumentList.Add($argument) }
    $info.WorkingDirectory = $folder
    $info.UseShellExecute = $false
    # No console window: the package and the test it starts share this hidden console instead of opening one on the user's screen.
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    foreach ($pair in @{ LOCALAPPDATA = $store; HTTPS_PROXY = 'http://127.0.0.1:9'; HTTP_PROXY = 'http://127.0.0.1:9'; NO_PROXY = '' }.GetEnumerator()) { $info.Environment[$pair.Key] = [string]$pair.Value }
    $process = [Diagnostics.Process]::Start($info)
    $process.StandardInput.Close()
    $out = $process.StandardOutput.ReadToEndAsync()
    $err = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(300000)) { $process.Kill($true); throw 'Launch timed out.' }
    $process.WaitForExit()

    return [pscustomobject]@{ Code = $process.ExitCode; Out = $out.Result; Err = $err.Result }
}

function Get-Status {
    $launch = Invoke-Launch @('--internal-status')
    $lines = @($launch.Out.Split([char[]]@([char]13, [char]10), [StringSplitOptions]::RemoveEmptyEntries) | Where-Object { $_.StartsWith('{', [StringComparison]::Ordinal) })
    if ($launch.Code -ne 0 -or $lines.Count -eq 0) { throw "Status failed: exit $($launch.Code) $($launch.Out) $($launch.Err)" }

    return $lines[-1] | ConvertFrom-Json
}

try {
    # The engine trust a confirmed first launch of the base would record, written with the base's own functions.
    $trust = Join-Path $scratchRoot 'trust.ps1'
    $body = (& (Join-Path $PSScriptRoot '..\tools\Get-PayloadDefinitions.ps1') -Path $package) + "`r`n" + '$identity = Get-Dlss5BootstrapIdentity -Bytes ([IO.File]::ReadAllBytes($SelfPath)) -Strict; $script:Dlss5ExecutingEngineSha256 = $identity.EngineSha256; $lock = Enter-Dlss5BootstrapLock; try { Write-Dlss5EngineTrust $identity } finally { Exit-Dlss5BootstrapLock $lock }'
    [IO.File]::WriteAllText($trust, $body, [Text.UTF8Encoding]::new($false))
    $previous = $env:LOCALAPPDATA
    try {
        $env:LOCALAPPDATA = $store
        & pwsh -NoProfile -File $trust -SelfPath $package
        if ($LASTEXITCODE -ne 0) { throw 'Recording the base engine trust failed.' }
    }
    finally { $env:LOCALAPPDATA = $previous }
    $status = Get-Status
    if ($status.mission_id -cne 'hello-world' -or $status.gate -cne 'none-required' -or $status.test_records -ne 0) { throw "Unexpected base status: $($status | ConvertTo-Json -Compress)" }
    $run = Invoke-Launch @('--internal-run-test', $status.expect, 'hello')
    if ($run.Code -ne 0 -or -not $run.Out.Contains('Hello from the test hello at a target location.') -or -not $run.Out.Contains('Test hello: pass, recorded.')) { throw "The base test did not pass: exit $($run.Code) $($run.Out) $($run.Err)" }
    $after = Get-Status
    if ($after.test_records -ne 1 -or $after.armed) { throw "The pass was not recorded: $($after | ConvertTo-Json -Compress)" }
    $arm = Invoke-Launch @('--internal-arm', $after.expect)
    if ($arm.Code -ne 0) { throw "The base did not arm headless: $($arm.Out) $($arm.Err)" }
    'hello-world base: test hello passed and was recorded, gate none-required, arms headless without a question: PASS'
}
finally { Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue }
