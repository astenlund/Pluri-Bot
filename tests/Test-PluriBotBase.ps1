param(
    [string]$UpdaterPath = (Join-Path $PSScriptRoot '..\build\DLSS5-ADDER.cmd'),
    # The engine file the base was assembled from; by default the one built beside it.
    [string]$EnginePath = '',
    [string]$MissionPath = (Join-Path $PSScriptRoot '..\missions\hello-world')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The release-suite cases that read the hello-world base, which Pluri-Bot owns: the base carries the engine it was assembled from and
# runs as a plain mission, the single-instance guard holds its folder, and its store view lists the engine file and the removable records
# but no record of its own. The helper functions, the case runner and its filter included, are copied unchanged from the DLSS5-Bot release
# suite, until the engine cases and their harness move here. The launches use isolated stores and a stub host; run this file only through
# tools/Invoke-SuiteOffscreen.ps1.
$UpdaterPath = [IO.Path]::GetFullPath($UpdaterPath)
if ($EnginePath.Length -eq 0) { $EnginePath = Join-Path (Split-Path -Parent $UpdaterPath) 'engine.cmd' }
$EnginePath = [IO.Path]::GetFullPath($EnginePath)
$MissionPath = [IO.Path]::GetFullPath($MissionPath)
$script:Passed = 0
$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:CasesRun = 0
$script:CaseTimes = [System.Collections.Generic.List[object]]::new()
$script:ScratchBase = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'DLSS5-ADDER/test-runs'))
[IO.Directory]::CreateDirectory($script:ScratchBase) | Out-Null
$script:ScratchRoot = Join-Path $script:ScratchBase ('pluri-bot-base-' + [Guid]::NewGuid().ToString('N'))

function Invoke-Dlss5Case {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    # DLSS5_TEST_CASE_FILTER, a regular expression over case names, and DLSS5_TEST_FILE_FILTER, semicolon-separated test file names, run only the cases both select.
    # In a filtered run, a selected case is named as it starts, for finding a hang.
    $caseFilter = [Environment]::GetEnvironmentVariable('DLSS5_TEST_CASE_FILTER')
    $fileFilter = [Environment]::GetEnvironmentVariable('DLSS5_TEST_FILE_FILTER')
    $file = [IO.Path]::GetFileName($Action.File)
    if (-not [string]::IsNullOrEmpty($caseFilter) -and $Name -notmatch $caseFilter) { return }
    if (-not [string]::IsNullOrEmpty($fileFilter) -and $file -notin $fileFilter.Split(';')) { return }
    if (Test-Dlss5SuiteFiltered) { Write-Host "RUN $Name" }
    $script:CasesRun++
    $outcome = 'PASS'
    $clock = [Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $script:Passed++
        Write-Host "PASS $Name"
    }
    catch {
        $outcome = 'FAIL'
        $script:Failures.Add("FAIL ${Name}: $($_.Exception.Message)")
    }
    $script:CaseTimes.Add([pscustomobject]@{ Milliseconds = $clock.ElapsedMilliseconds; Name = $Name })
    Write-Host "TIME $($clock.ElapsedMilliseconds) $outcome $file $Name"
}

function Test-Dlss5SuiteFiltered {
    return -not ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('DLSS5_TEST_CASE_FILTER')) -and [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('DLSS5_TEST_FILE_FILTER')))
}

function Assert-Dlss5Equal {
    param(
        [object]$Actual,
        [object]$Expected,
        [string]$Message
    )

    if (-not [object]::Equals($Actual, $Expected)) {
        throw "$Message Expected=[$Expected] Actual=[$Actual]"
    }
}

function Assert-Dlss5True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function New-Dlss5CandidateLibrary {
    param([string]$Path)

    $resolvedPath = (Resolve-Path $Path).Path
    $text = Get-Content -LiteralPath $resolvedPath -Raw
    $begin = '### === POWERSHELL_PAYLOAD_BEGIN ==='
    $main = '# Load and normalize persistent state'
    $start = $text.IndexOf($begin, [StringComparison]::Ordinal)
    $stop = $text.IndexOf($main, [StringComparison]::Ordinal)
    if ($start -lt 0 -or $stop -le $start) {
        throw 'Candidate library anchors are missing or reversed.'
    }

    $library = $text.Substring($start + $begin.Length, $stop - ($start + $begin.Length))
    $scratch = Join-Path $script:ScratchRoot ('library-' + [Guid]::NewGuid().ToString('N') + '.ps1')
    [IO.File]::WriteAllText($scratch, $library, [Text.UTF8Encoding]::new($false))

    return [pscustomobject]@{ Path = $scratch; SelfPath = $resolvedPath }
}

function Invoke-Dlss5WithLocalAppData {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][scriptblock]$Action
    )

    New-Item -ItemType Directory -Force $Path | Out-Null
    $prior = $env:LOCALAPPDATA
    try {
        $env:LOCALAPPDATA = $Path

        return & $Action
    }
    finally {
        $env:LOCALAPPDATA = $prior
    }
}

function New-Dlss5TargetExecutable {
    param([Parameter(Mandatory=$true)][string]$GameDirectory)

    $bin = Join-Path $GameDirectory 'bin'
    New-Item -ItemType Directory -Force $bin | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $bin 'game.exe'), [byte[]](1))
}

function New-Dlss5IsolatedLaunchFixture {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$GameDirectory = '',
        [string[]]$StubBody = @()
    )

    # Agent selection accepts only a claude or codex command name; an explicit Claude model pins the launch arguments independent of the updater default.
    $root = Join-Path $script:ScratchRoot $Name
    $game = if ($GameDirectory.Length -gt 0) { $GameDirectory } else { Join-Path $root 'game' }
    $localAppData = Join-Path $root 'localappdata'
    $stubRoot = Join-Path $root 'agent'
    New-Item -ItemType Directory -Force $game, $localAppData, $stubRoot | Out-Null
    # The DLSS mission's target asks for a game executable within two folder levels; one in a subfolder leaves the top-level fingerprint unchanged.
    if ($GameDirectory.Length -eq 0) { New-Dlss5TargetExecutable $game }
    $updater = Join-Path $game 'DLSS5-ADDER.cmd'
    Copy-Item -LiteralPath $UpdaterPath -Destination $updater
    $stub = Join-Path $stubRoot 'claude.cmd'
    $body = @('@echo off') + $StubBody + @('exit /b %ERRORLEVEL%')
    [IO.File]::WriteAllText($stub, ($body -join "`r`n") + "`r`n", [Text.ASCIIEncoding]::new())

    return [pscustomobject]@{
        Root = $root
        Game = $game
        Updater = $updater
        GameNotesPath = Join-Path $game 'DLSS5-ADDER.md'
        LocalAppData = $localAppData
        MachineDirectory = Join-Path $localAppData 'DLSS5-ADDER'
        StubRoot = $stubRoot
        Stub = $stub
    }
}

function Invoke-Dlss5ProcessWithInput {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Arguments,
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][string[]]$InputLines,
        [string]$WorkingDirectory = '',
        [hashtable]$Environment = @{}
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    if ($WorkingDirectory.Length -gt 0) { $startInfo.WorkingDirectory = $WorkingDirectory }
    # A null value removes the variable from the child's environment, as an unset variable rather than an empty one.
    foreach ($key in $Environment.Keys) {
        if ($null -eq $Environment[$key]) { [void]$startInfo.Environment.Remove($key) }
        else { $startInfo.Environment[$key] = [string]$Environment[$key] }
    }
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Process did not start: $FilePath"
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        foreach ($line in $InputLines) {
            $process.StandardInput.WriteLine($line)
        }
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(300000)) {
            $process.Kill($true)
            throw [TimeoutException]::new("Process did not exit within five minutes: $FilePath $($Arguments -join ' ')")
        }
        # A grandchild such as the update worker inherits the output pipes and can hold them open after the process exits.
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdoutTask, $stderrTask), 60000)) {
            throw [TimeoutException]::new("Process output stayed open for a minute after exit: $FilePath $($Arguments -join ' ')")
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = $stdoutTask.GetAwaiter().GetResult()
            StandardError = $stderrTask.GetAwaiter().GetResult()
        }
    }
    finally {
        $process.Dispose()
    }
}

function New-Dlss5TrustFixture {
    param([hashtable]$Whole = @{}, [hashtable]$Engine = @{})

    $notes = [Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
    $notes['schema_version'] = '1'
    if ($Whole.Count -gt 0) { $notes['bootstrap_highest_version_seen'] = [string](($Whole.Keys | Measure-Object -Maximum).Maximum) }
    foreach ($version in $Whole.Keys) { $notes["bootstrap_checksum.$version"] = $Whole[$version] }
    if ($Engine.Count -gt 0) { $notes['bootstrap_engine_highest_version_seen'] = [string](($Engine.Keys | Measure-Object -Maximum).Maximum) }
    foreach ($version in $Engine.Keys) { $notes["bootstrap_engine_checksum.$version"] = $Engine[$version] }

    return [pscustomobject]@{ Notes = $notes; Trust = Get-Dlss5TrustMap $notes }
}

function Write-Dlss5MachineTrustFixture {
    param([Parameter(Mandatory=$true)][string]$MachineDirectory, [hashtable]$Whole = @{}, [hashtable]$Engine = @{})

    New-Item -ItemType Directory -Force $MachineDirectory | Out-Null
    $fixture = New-Dlss5TrustFixture -Whole $Whole -Engine $Engine
    $text = ConvertTo-Dlss5NotesDocument -Notes $fixture.Notes -BeginMarker $MachineNotesBeginMarker -EndMarker $MachineNotesEndMarker -KnownOrder $MachineNotesOrder
    [IO.File]::WriteAllText((Join-Path $MachineDirectory 'DLSS5_MACHINE_NOTES.md'), $text, [Text.UTF8Encoding]::new($false))
}

function New-Dlss5SubstitutedConsole {
    param([object[]]$Keys)

    # Each entry is a key name or a single character, optionally with the milliseconds that pass before it arrives.
    $queue = [Collections.Generic.List[object]]::new()
    foreach ($entry in $Keys) {
        if ($entry -is [hashtable]) { $queue.Add([pscustomobject]@{ Key = $entry.Key; Char = [char]$entry.Char; Delay = $entry.Delay }); continue }
        $text = [string]$entry
        if ($text.Length -eq 1) { $queue.Add([pscustomobject]@{ Key = [string][char]::ToUpperInvariant($text[0]); Char = $text[0]; Delay = 1000 }) }
        else { $queue.Add([pscustomobject]@{ Key = $text; Char = [char]0; Delay = 1000 }) }
    }

    return [pscustomobject]@{ Queue = $queue; Output = [Collections.Generic.List[string]]::new() }
}

# Runs an in-process package interaction against a game-local copy under an isolated store, with the given keys on a substituted console.
function Invoke-Dlss5PackageInteraction {
    param([Parameter(Mandatory=$true)][string]$Name, [Parameter(Mandatory=$true)][byte[]]$Bytes, [Parameter(Mandatory=$true)][scriptblock]$Action, $Diagnosis = $null)

    $root = Join-Path $script:ScratchRoot $Name
    $game = Join-Path $root 'game'
    New-Item -ItemType Directory -Force $game | Out-Null
    $packagePath = Join-Path $game 'DLSS5-ADDER.cmd'
    [IO.File]::WriteAllBytes($packagePath, $Bytes)
    $saved = @{ Identity = (Get-Variable -Name Dlss5ExecutingIdentity -Scope Script -ValueOnly -ErrorAction SilentlyContinue); Startup = (Get-Variable -Name Dlss5Startup -Scope Script -ValueOnly -ErrorAction SilentlyContinue); Console = $script:Dlss5Console; Engine = (Get-Variable -Name Dlss5ExecutingEngineSha256 -Scope Script -ValueOnly -ErrorAction SilentlyContinue) }
    # Invoke-Dlss5WithLocalAppData has its own Action parameter, which would shadow this one inside the block below.
    $interaction = $Action
    try {
        return Invoke-Dlss5WithLocalAppData -Path (Join-Path $root 'localappdata') -Action {
            New-Item -ItemType Directory -Force (Get-Dlss5StorePath) | Out-Null
            $script:Dlss5ExecutingEngineSha256 = $script:CandidateIdentity.EngineSha256
            $script:Dlss5ExecutingIdentity = Get-Dlss5BootstrapIdentity -Bytes $Bytes -Strict
            $script:Dlss5Startup = [pscustomobject]@{ Diagnosis = $Diagnosis }

            return & $interaction $packagePath $game
        }
    }
    finally { $script:Dlss5ExecutingIdentity = $saved.Identity; $script:Dlss5Startup = $saved.Startup; $script:Dlss5Console = $saved.Console; $script:Dlss5ExecutingEngineSha256 = $saved.Engine }
}

function Start-Dlss5GuardHolder {
    param(
        [Parameter(Mandatory=$true)][string]$Package,
        [Parameter(Mandatory=$true)][string]$LocalAppData,
        [string]$Operation = 'execute',
        [string]$HostKind = 'claude',
        [switch]$NoRecord,
        [string]$ChildArguments = ''
    )

    # Holds the package folder's guard from a separate process until Stop-Dlss5GuardHolder, as a running session would.
    $id = [Guid]::NewGuid().ToString('N').Substring(0, 12)
    $base = Join-Path (Split-Path -Parent $Package) ('..\holder-' + $id)
    $holder = [pscustomobject]@{ Ready = [IO.Path]::GetFullPath($base + '.ready'); Release = [IO.Path]::GetFullPath($base + '.release'); Result = [IO.Path]::GetFullPath($base + '.json'); Process = $null; ProcessId = 0 }
    $info = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($argument in @('-NoProfile', '-File', (Join-Path $PSScriptRoot 'Hold-DLSS5Guard.ps1'), '-Library', $script:Library.Path, '-SelfPath', $script:Library.SelfPath, '-Package', $Package, '-LocalAppData', $LocalAppData, '-ReadyPath', $holder.Ready, '-ReleasePath', $holder.Release, '-Operation', $Operation)) { $info.ArgumentList.Add($argument) }
    if ($HostKind.Length -gt 0) { $info.ArgumentList.Add('-HostKind'); $info.ArgumentList.Add($HostKind) }
    if ($NoRecord) { $info.ArgumentList.Add('-NoRecord') }
    if ($ChildArguments.Length -gt 0) { foreach ($argument in @('-ChildArguments', $ChildArguments, '-ChildResultPath', $holder.Result)) { $info.ArgumentList.Add($argument) } }
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $holder.Process = [Diagnostics.Process]::Start($info)
    $holder.ProcessId = $holder.Process.Id
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath $holder.Ready)) {
        if ($holder.Process.HasExited) { throw "The guard holder exited with code $($holder.Process.ExitCode) before it was ready." }
        if ($timer.Elapsed.TotalSeconds -gt 120) { $holder.Process.Kill($true); throw 'The guard holder did not become ready within two minutes.' }
        Start-Sleep -Milliseconds 50
    }

    return $holder
}

function Stop-Dlss5GuardHolder {
    param([Parameter(Mandatory=$true)]$Holder, [switch]$Kill)

    if ($Kill) { $Holder.Process.Kill($true) }
    else { [IO.File]::WriteAllText($Holder.Release, 'release') }
    if (-not $Holder.Process.WaitForExit(60000)) { $Holder.Process.Kill($true); throw 'The guard holder did not exit.' }
    $Holder.Process.Dispose()
}

function Get-Dlss5HolderText {
    param([Parameter(Mandatory=$true)]$Holder, [string]$Label = 'session', [string]$HostKind = 'claude')

    # The refusal names the holder's process and, for a session whose agent was selected, its host.
    $start = [Diagnostics.Process]::GetProcessById($Holder.ProcessId).StartTime.ToUniversalTime()
    $local = [datetime]::new($start.Ticks - ($start.Ticks % [TimeSpan]::TicksPerSecond), [DateTimeKind]::Utc).ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
    $hostPart = if ($HostKind.Length -gt 0) { ', host ' + $HostKind } else { '' }

    return "another DLSS 5 ADDER $Label is running for this folder (process $($Holder.ProcessId), started $local$hostPart)."
}

function Get-Dlss5TestLocationFolderName {
    param([Parameter(Mandatory=$true)][string]$Path)

    # The record folder name the design gives a location path: every run of characters outside [A-Za-z0-9] as one hyphen, at most 80
    # characters, then a hyphen and the first 16 hex characters of the SHA-256 of the upper-cased path.
    $hash = (Get-Sha256Text -Text $Path.ToUpperInvariant()).Substring(0, 16)
    $encoded = [regex]::Replace($Path, '[^A-Za-z0-9]+', '-')
    if ($encoded.Length -gt 80) { $encoded = $encoded.Substring(0, 80) }

    return $encoded + '-' + $hash
}

function Write-Dlss5TestLocationRecord {
    param([Parameter(Mandatory=$true)][string]$LocationPath, [hashtable]$Fields = @{}, [string]$FolderName = '')

    # Writes a record straight into the current store, as an earlier session at that location would have, and returns its folder.
    if ($FolderName.Length -eq 0) { $FolderName = Get-Dlss5TestLocationFolderName $LocationPath }
    $folder = Join-Path (Get-Dlss5LocationsDirectory) $FolderName
    New-Item -ItemType Directory -Force $folder | Out-Null
    $notes = New-Dlss5LocationNotes
    $notes['location_path'] = $LocationPath
    foreach ($key in $Fields.Keys) { $notes[$key] = [string]$Fields[$key] }
    Write-Dlss5LocationNotes -Path (Join-Path $folder 'LOCATION.md') -Notes $notes

    return $folder
}

function Set-Dlss5FixtureArmed {
    param([Parameter(Mandatory=$true)]$Fixture)

    # Writes an armed state into the fixture copy, as Arm would, and returns its identity; an updater without packages is left alone.
    $bytes = [IO.File]::ReadAllBytes($Fixture.Updater)
    $identity = Get-Dlss5BootstrapIdentity -Bytes $bytes
    if ($null -eq $identity.PSObject.Properties['Sectioned'] -or -not $identity.Sectioned) { return $null }
    if (-not $identity.State.Armed) {
        $state = [pscustomobject]@{ Empty = $false; Armed = $true; MissionEdited = $identity.State.MissionEdited; ReplacedMissionHash = $identity.State.ReplacedMissionHash; Update = $null }
        $bytes = Set-Dlss5PackageSections -Bytes $bytes -Bodies ([ordered]@{ STATE = (ConvertTo-Dlss5StateBody $state) })
        [IO.File]::WriteAllBytes($Fixture.Updater, $bytes)
        $identity = Get-Dlss5BootstrapIdentity -Bytes $bytes
    }

    return $identity
}

function Invoke-Dlss5IsolatedLaunch {
    param(
        [Parameter(Mandatory=$true)]$Fixture,
        [hashtable]$Environment = @{},
        [AllowEmptyCollection()][string[]]$Arguments,
        [string]$WorkingDirectory = ''
    )

    if ($WorkingDirectory.Length -eq 0) { $WorkingDirectory = $Fixture.Game }
    # A package opens a menu on a plain launch, so without explicit arguments the fixture copy is armed and Execute runs headless,
    # which is what a no-argument launch did before packages. Updaters without packages keep the no-argument launch.
    if (-not $PSBoundParameters.ContainsKey('Arguments')) {
        $identity = Set-Dlss5FixtureArmed $Fixture
        # An if-expression yielding @() collapses to $null, which a [string[]] variable turns into one empty argument.
        $Arguments = [string[]]@()
        if ($null -ne $identity) { $Arguments = [string[]]@('--internal-execute', (Get-Dlss5ExpectationToken $identity)) }
    }

    # The dead proxy makes the background update check fail fast offline instead of querying or staging the published release.
    $variables = @{
        DLSS5_AGENT_HOST = $Fixture.Stub
        DLSS5_AGENT = $Fixture.Stub
        DLSS5_CLAUDE_MODEL = 'opus'
        LOCALAPPDATA = $Fixture.LocalAppData
        HTTPS_PROXY = 'http://127.0.0.1:9'
        HTTP_PROXY = 'http://127.0.0.1:9'
        NO_PROXY = ''
    }
    foreach ($key in $Environment.Keys) { $variables[$key] = $Environment[$key] }

    return Invoke-Dlss5ProcessWithInput -FilePath 'cmd.exe' -Arguments (@('/d', '/c', $Fixture.Updater) + $Arguments) -InputLines @() -WorkingDirectory $WorkingDirectory -Environment $variables
}

function Get-Dlss5LaunchStatus {
    param([Parameter(Mandatory=$true)]$Fixture, [hashtable]$Environment = @{})

    $process = Invoke-Dlss5IsolatedLaunch -Fixture $Fixture -Arguments @('--internal-status') -Environment $Environment
    Assert-Dlss5Equal $process.ExitCode 0 "Status launch failed: $($process.StandardError) $($process.StandardOutput)"
    $line = @($process.StandardOutput.Split([char[]]@([char]13, [char]10), [StringSplitOptions]::RemoveEmptyEntries) | Where-Object { $_.StartsWith('{', [StringComparison]::Ordinal) })[-1]

    return $line | ConvertFrom-Json
}
New-Item -ItemType Directory -Force $script:ScratchRoot | Out-Null
$script:Library = $null

try {
    $script:Library = New-Dlss5CandidateLibrary -Path $UpdaterPath
    . $script:Library.Path -SelfPath $script:Library.SelfPath
    # Normal launcher mode initializes this before any agent launch; strict mode rejects reading it unset.
    $script:Dlss5Channel = $null
    $script:CandidateBytes = [IO.File]::ReadAllBytes($UpdaterPath)
    $script:CandidateIdentity = Get-Dlss5BootstrapIdentity -Bytes $script:CandidateBytes -Strict
    $script:CandidateVersion = $script:CandidateIdentity.Version
    $script:EngineSha256 = [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($EnginePath)))

    Invoke-Dlss5Case 'package hello-world base shares the engine and runs as a plain mission' {
        $baseBytes = $script:CandidateBytes
        $base = $script:CandidateIdentity
        Assert-Dlss5True ($base.MissionId -ceq 'hello-world' -and $base.EngineSha256 -ceq $script:EngineSha256 -and $base.PublishedSha256 -ceq $base.Sha256 -and $base.State.Empty -and -not $base.Project.Rerun) 'The base is not a published hello-world package on the engine file''s engine.'
        $fixture = New-Dlss5IsolatedLaunchFixture -Name 'package-base' -StubBody @('exit /b 0')
        [IO.File]::WriteAllBytes($fixture.Updater, $baseBytes)
        Write-Dlss5MachineTrustFixture -MachineDirectory $fixture.MachineDirectory -Engine @{ $script:CandidateVersion = $base.EngineSha256 }
        $status = Get-Dlss5LaunchStatus $fixture
        Assert-Dlss5Equal (Invoke-Dlss5IsolatedLaunch -Fixture $fixture -Arguments @('--internal-accept', $status.expect)).ExitCode 0 'The base''s new-package box could not be accepted.'
        $run = Invoke-Dlss5IsolatedLaunch -Fixture $fixture -Arguments @('--internal-execute', $status.expect)
        Assert-Dlss5Equal $run.ExitCode 0 "The base did not run: $($run.StandardOutput) $($run.StandardError)"
        Assert-Dlss5True (-not (Get-Dlss5LaunchStatus $fixture).armed) 'The base stayed armed after a run.'
        $folder = Join-Path $fixture.Root 'edits'
        New-Item -ItemType Directory -Force $folder | Out-Null
        $mission = [IO.File]::ReadAllText((Join-Path $MissionPath 'MISSION.md')).Replace('{{package_dir}}', '{{package_dir}} (edited)')
        [IO.File]::WriteAllText((Join-Path $folder 'MISSION.md'), $mission)
        $absorb = Invoke-Dlss5IsolatedLaunch -Fixture $fixture -Arguments @('--internal-absorb', (Get-Dlss5LaunchStatus $fixture).expect, $folder)
        Assert-Dlss5Equal $absorb.ExitCode 0 "The base did not absorb a mission edit: $($absorb.StandardOutput) $($absorb.StandardError)"
        Assert-Dlss5True (Get-Dlss5BootstrapIdentity -Bytes ([IO.File]::ReadAllBytes($fixture.Updater)) -Strict).State.MissionEdited 'The base''s absorb did not mark the mission as edited.'
    }

    Invoke-Dlss5Case 'guard holds the hello-world base folder too' {
        $baseBytes = $script:CandidateBytes
        $fixture = New-Dlss5IsolatedLaunchFixture -Name 'guard-base' -StubBody @('echo started>"%DLSS5_TEST_STARTED_PATH%"')
        $started = Join-Path $fixture.StubRoot 'started.txt'
        [IO.File]::WriteAllBytes($fixture.Updater, $baseBytes)
        Write-Dlss5MachineTrustFixture -MachineDirectory $fixture.MachineDirectory -Engine @{ $script:CandidateVersion = (Get-Dlss5BootstrapIdentity -Bytes $baseBytes).EngineSha256 }
        $status = Get-Dlss5LaunchStatus $fixture
        Assert-Dlss5Equal (Invoke-Dlss5IsolatedLaunch -Fixture $fixture -Arguments @('--internal-accept', $status.expect)).ExitCode 0 'The base''s new-package box could not be accepted.'
        $holder = Start-Dlss5GuardHolder -Package $fixture.Updater -LocalAppData $fixture.LocalAppData
        try {
            $process = Invoke-Dlss5IsolatedLaunch -Fixture $fixture -Arguments @('--internal-execute', $status.expect) -Environment @{ DLSS5_TEST_STARTED_PATH = $started }
            Assert-Dlss5True ($process.ExitCode -eq 8 -and $process.StandardOutput.Contains('Execute refused: ' + (Get-Dlss5HolderText $holder))) "The base ran while another process held its folder (exit $($process.ExitCode)): $($process.StandardOutput)"
            Assert-Dlss5True (-not (Test-Path -LiteralPath $started)) 'The base started its agent while another process held its folder.'
        }
        finally { Stop-Dlss5GuardHolder $holder }
    }

    Invoke-Dlss5Case 'store menu of the hello-world base lists the engine file and the removable records, but no record of its own' {
        $opened = [Collections.Generic.List[string]]::new()
        $savedOpen = $script:Dlss5OpenFile
        $script:Dlss5OpenFile = { param($FilePath) $opened.Add($FilePath) }
        try {
            Invoke-Dlss5PackageInteraction -Name 'store-menu-base' -Bytes $script:CandidateBytes -Action {
                param($PackagePath, $Game)
                $orphan = Write-Dlss5TestLocationRecord -LocationPath 'C:\Gone\Slot Game' -Fields @{ folder_token = ('e' * 48); game_fingerprint = ('c' * 64); transaction_status = 'stage 1' }
                $unreadable = Join-Path (Get-Dlss5LocationsDirectory) (Get-Dlss5TestLocationFolderName 'C:\Gone\Slot Broken')
                New-Item -ItemType Directory -Force $unreadable | Out-Null
                $view = Get-Dlss5StoreView -Path $PackagePath
                Assert-Dlss5True ($null -eq $view.OwnStatus -and $view.Removable.Count -eq 2) "The base view did not list the records without one of its own: $($view.OwnStatus) $($view.Removable.Count)"
                foreach ($target in @($orphan, $unreadable)) {
                    $index = [array]::IndexOf(@((Get-Dlss5StoreView -Path $PackagePath).Removable | ForEach-Object { $_.Folder.Path }), $target) + 1
                    $script:Dlss5Console = New-Dlss5SubstitutedConsole @([string]$index, 'Enter', 'y', 'Enter', 'Escape')
                    Invoke-Dlss5StoreMenu -Path $PackagePath
                    $output = $script:Dlss5Console.Output -join "`n"
                    Assert-Dlss5Equal (Test-Path -LiteralPath $target) $false "The base view did not remove $target"
                    Assert-Dlss5True (-not $output.Contains('This location''s record')) 'The base view showed a record of its own.'
                }
            }
        }
        finally { $script:Dlss5OpenFile = $savedOpen }
    }
}
finally {
    if ($null -ne $script:Library -and (Test-Path -LiteralPath $script:Library.Path)) { Remove-Item -LiteralPath $script:Library.Path -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $script:ScratchRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# A run that selected nothing has checked nothing, so it must not read as a pass.
if ($script:CasesRun -eq 0) {
    Write-Host 'NO CASES RAN: the run selected nothing.'
    exit 1
}

if ($script:Failures.Count -gt 0) {
    foreach ($failure in $script:Failures) { Write-Host $failure }
    Write-Host "$($script:Failures.Count) FAILED, $script:Passed PASSED"
    exit 1
}

Write-Host "ALL TESTS PASSED ($script:Passed)"
exit 0
