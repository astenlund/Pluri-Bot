param(
    [Parameter(Mandatory = $true)][string]$Library,
    [Parameter(Mandatory = $true)][string]$SelfPath,
    [Parameter(Mandatory = $true)][string]$Package,
    [Parameter(Mandatory = $true)][string]$LocalAppData,
    [Parameter(Mandatory = $true)][string]$ReadyPath,
    [Parameter(Mandatory = $true)][string]$ReleasePath,
    [string]$Operation = 'execute',
    [string]$HostKind = '',
    [switch]$NoRecord,
    [string]$ChildArguments = '',
    [string]$ChildResultPath = ''
)

# Release-suite helper: holds a package folder's single-instance guard from a separate process, as a running session would,
# until the release file appears. With -ChildArguments it runs one cmd.exe child of itself under the hold and records its
# exit code and output, which is how an adoption approved inside the holding session runs.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:LOCALAPPDATA = $LocalAppData
. $Library -SelfPath $SelfPath
$token = Enter-Dlss5FolderGuard -Path $Package -Operation $Operation
if ($HostKind.Length -gt 0) { Update-Dlss5FolderGuardHost $HostKind }
if ($NoRecord) { Remove-Dlss5GuardRecord $script:Dlss5GuardHolds[$token] }
if ($ChildArguments.Length -gt 0) {
    $info = [Diagnostics.ProcessStartInfo]::new('cmd.exe', $ChildArguments)
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.WorkingDirectory = Split-Path -Parent $Package
    $child = [Diagnostics.Process]::Start($info)
    $stdout = $child.StandardOutput.ReadToEndAsync()
    $stderr = $child.StandardError.ReadToEndAsync()
    if (-not $child.WaitForExit(120000)) { $child.Kill($true); throw 'The child did not exit within two minutes.' }
    $result = [ordered]@{ code = $child.ExitCode; out = $stdout.GetAwaiter().GetResult(); err = $stderr.GetAwaiter().GetResult() }
    [IO.File]::WriteAllText($ChildResultPath, (ConvertTo-Json -InputObject $result -Compress), [Text.UTF8Encoding]::new($false))
}
[IO.File]::WriteAllText($ReadyPath, [string]$PID, [Text.UTF8Encoding]::new($false))
$timer = [Diagnostics.Stopwatch]::StartNew()
while (-not (Test-Path -LiteralPath $ReleasePath) -and $timer.Elapsed.TotalMinutes -lt 10) { Start-Sleep -Milliseconds 50 }
Exit-Dlss5FolderGuard $token
