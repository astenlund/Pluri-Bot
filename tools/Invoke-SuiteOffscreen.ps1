param(
    [string]$UpdaterPath = '',
    [string]$OutputPath = '',
    [string]$Suite = '',
    [switch]$RestoreOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Runs the release suite on a private, never-shown desktop. Child processes inherit their parent's desktop,
# including console windows that ShellExecute opens for batch agent stubs, so no window reaches the user's screen.
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Dlss5OffscreenDesktop
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct StartupInfo
    {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX; public int dwY; public int dwXSize; public int dwYSize;
        public int dwXCountChars; public int dwYCountChars; public int dwFillAttribute;
        public int dwFlags; public short wShowWindow; public short cbReserved2;
        public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ProcessInformation { public IntPtr hProcess; public IntPtr hThread; public int dwProcessId; public int dwThreadId; }

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateDesktop(string name, IntPtr device, IntPtr devMode, int flags, uint access, IntPtr attributes);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool CloseDesktop(IntPtr desktop);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CreateProcess(string application, System.Text.StringBuilder commandLine, IntPtr processAttributes, IntPtr threadAttributes,
        bool inheritHandles, uint flags, IntPtr environment, string directory, ref StartupInfo startup, out ProcessInformation information);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetExitCodeProcess(IntPtr process, out uint exitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [StructLayout(LayoutKind.Sequential)]
    private struct BasicLimitInformation
    {
        public long PerProcessUserTimeLimit; public long PerJobUserTimeLimit; public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize; public UIntPtr MaximumWorkingSetSize; public uint ActiveProcessLimit;
        public UIntPtr Affinity; public uint PriorityClass; public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct IoCounters
    {
        public ulong ReadOperationCount; public ulong WriteOperationCount; public ulong OtherOperationCount;
        public ulong ReadTransferCount; public ulong WriteTransferCount; public ulong OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ExtendedLimitInformation
    {
        public BasicLimitInformation BasicLimitInformation; public IoCounters IoInfo;
        public UIntPtr ProcessMemoryLimit; public UIntPtr JobMemoryLimit; public UIntPtr PeakProcessMemoryUsed; public UIntPtr PeakJobMemoryUsed;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr attributes, string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetInformationJobObject(IntPtr job, int infoClass, ref ExtendedLimitInformation info, int length);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint ResumeThread(IntPtr thread);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool TerminateProcess(IntPtr process, uint exitCode);

    private const uint GenericAll = 0x10000000;
    private const uint CreateNewConsole = 0x00000010;
    private const uint CreateSuspended = 0x00000004;
    private const uint Infinite = 0xFFFFFFFF;
    private const int ExtendedLimitInformationClass = 9;
    private const uint KillOnJobClose = 0x00002000;

    // The whole suite tree runs in a job that the kernel kills when its last handle closes, so killing or crashing
    // the runner never leaves suite processes running on the hidden desktop.
    private static IntPtr CreateKillOnCloseJob()
    {
        IntPtr job = CreateJobObject(IntPtr.Zero, null);
        if (job == IntPtr.Zero) { throw new System.ComponentModel.Win32Exception(); }
        var info = new ExtendedLimitInformation();
        info.BasicLimitInformation.LimitFlags = KillOnJobClose;
        if (!SetInformationJobObject(job, ExtendedLimitInformationClass, ref info, Marshal.SizeOf(typeof(ExtendedLimitInformation))))
        {
            int error = Marshal.GetLastWin32Error();
            CloseHandle(job);
            throw new System.ComponentModel.Win32Exception(error);
        }

        return job;
    }

    public static int Run(string commandLine, string directory)
    {
        string name = "dlss5-suite-" + Guid.NewGuid().ToString("N");
        IntPtr desktop = CreateDesktop(name, IntPtr.Zero, IntPtr.Zero, 0, GenericAll, IntPtr.Zero);
        if (desktop == IntPtr.Zero) { throw new System.ComponentModel.Win32Exception(); }
        IntPtr job = IntPtr.Zero;
        try
        {
            job = CreateKillOnCloseJob();
            var startup = new StartupInfo();
            startup.cb = Marshal.SizeOf(typeof(StartupInfo));
            startup.lpDesktop = name;
            ProcessInformation information;
            if (!CreateProcess(null, new System.Text.StringBuilder(commandLine), IntPtr.Zero, IntPtr.Zero, false, CreateNewConsole | CreateSuspended, IntPtr.Zero, directory, ref startup, out information))
            {
                throw new System.ComponentModel.Win32Exception();
            }
            try
            {
                if (!AssignProcessToJobObject(job, information.hProcess))
                {
                    int error = Marshal.GetLastWin32Error();
                    TerminateProcess(information.hProcess, 1);
                    throw new System.ComponentModel.Win32Exception(error);
                }
                ResumeThread(information.hThread);
                WaitForSingleObject(information.hProcess, Infinite);
                uint exitCode;
                if (!GetExitCodeProcess(information.hProcess, out exitCode)) { throw new System.ComponentModel.Win32Exception(); }
                return (int)exitCode;
            }
            finally
            {
                CloseHandle(information.hThread);
                CloseHandle(information.hProcess);
            }
        }
        finally
        {
            if (job != IntPtr.Zero) { CloseHandle(job); }
            CloseDesktop(desktop);
        }
    }
}
'@

# Windows Terminal, when it is the default console host, shows every new console on the user's desktop regardless of
# the creating desktop. The user's standing preference is to use the classic console host for suite runs, so the
# per-user delegation is switched for the duration of the run and restored afterwards from a durable record.
$delegationKey = 'HKCU:\Console\%%Startup'
$delegationNames = @('DelegationConsole', 'DelegationTerminal')
$conhost = '{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}'
$recordPath = Join-Path $env:LOCALAPPDATA 'DLSS5-ADDER\test-runs\console-delegation-restore.json'

# Each delegation setting's current value, null where it is absent. A missing key confirms absence; any other read failure confirms nothing and stops the caller.
function Get-Dlss5ConsoleDelegation {
    try { $properties = Get-ItemProperty -LiteralPath $delegationKey -ErrorAction Stop }
    catch [Management.Automation.ItemNotFoundException] { $properties = $null }
    $values = @{}
    foreach ($name in $delegationNames) {
        $values[$name] = if ($null -ne $properties -and $null -ne $properties.PSObject.Properties[$name]) { [string]$properties.$name } else { $null }
    }
    return $values
}

# Written beside the record and moved into place, so a process dying during the write leaves a stray temporary file that nothing reads, never a truncated record.
function Write-Dlss5ConsoleDelegationRecord {
    param([Parameter(Mandatory)][hashtable]$Values)
    $temporary = "$recordPath.tmp"
    [IO.File]::WriteAllText($temporary, ($Values | ConvertTo-Json))
    [IO.File]::Move($temporary, $recordPath, $true)
}

function Restore-Dlss5ConsoleDelegation {
    $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json -AsHashtable
    # A record that does not state both values cannot say what to restore, so it and the current settings are left alone.
    if ($record -isnot [Collections.IDictionary]) { throw "The console host record at $recordPath is damaged; it and the current settings are left alone." }
    foreach ($name in $delegationNames) {
        if (-not $record.ContainsKey($name) -or ($null -ne $record[$name] -and $record[$name] -isnot [string])) { throw "The console host record at $recordPath does not state $name; it and the current settings are left alone." }
    }
    foreach ($name in $delegationNames) {
        $value = $record[$name]
        if ($null -eq $value) { Remove-ItemProperty -LiteralPath $delegationKey -Name $name -ErrorAction SilentlyContinue }
        else { Set-ItemProperty -LiteralPath $delegationKey -Name $name -Value $value }
    }
    # The removal above hides its errors, and the record is the only way back, so it goes only once every value is confirmed restored.
    $restored = Get-Dlss5ConsoleDelegation
    foreach ($name in $delegationNames) {
        if ($restored[$name] -cne $record[$name]) { throw "The console host setting $name was not restored; the record stays at $recordPath." }
    }
    Remove-Item -LiteralPath $recordPath
}

# Only one runner may own the delegation record. A record found while holding this mutex can only come from a run
# that was killed or whose restoration failed, so restoring it is safe; a live run makes this runner refuse to start.
$runnerMutex = [Threading.Mutex]::new($false, 'Local\DLSS5-ADDER-SUITE-RUNNER')
try { $owned = $runnerMutex.WaitOne(0) }
catch [Threading.AbandonedMutexException] { $owned = $true }
if (-not $owned) { throw 'Another suite run is live; wait for it to finish. Never start a second runner.' }

try {
if (Test-Path -LiteralPath $recordPath) {
    Write-Warning 'Restoring console delegation left behind by an earlier suite run.'
    Restore-Dlss5ConsoleDelegation
}
if ($RestoreOnly) {
    'console delegation restored or already clean'
    return
}
if ([string]::IsNullOrWhiteSpace($UpdaterPath) -or [string]::IsNullOrWhiteSpace($OutputPath)) { throw 'UpdaterPath and OutputPath are required unless -RestoreOnly is given.' }

$current = Get-Dlss5ConsoleDelegation
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $recordPath) | Out-Null
Write-Dlss5ConsoleDelegationRecord $current
if (-not (Test-Path -LiteralPath $delegationKey)) { New-Item -Path $delegationKey -Force | Out-Null }

try {
    foreach ($name in $delegationNames) { Set-ItemProperty -LiteralPath $delegationKey -Name $name -Value $conhost }
    $wrapper = Join-Path $PSScriptRoot 'Invoke-SuiteToFile.ps1'
    $pwsh = (Get-Command pwsh).Source
    $commandLine = '"{0}" -NoProfile -File "{1}" -UpdaterPath "{2}" -OutputPath "{3}"' -f $pwsh, $wrapper, $UpdaterPath, $OutputPath
    # Another script, such as a smoke run, can use the same hidden desktop; it receives -UpdaterPath, and its output goes to the output path.
    if ($Suite.Length -gt 0) { $commandLine += ' -Suite "{0}"' -f $Suite }
    $exitCode = [Dlss5OffscreenDesktop]::Run($commandLine, $PSScriptRoot)
}
finally {
    Restore-Dlss5ConsoleDelegation
}
"exit $exitCode"
}
finally {
    $runnerMutex.ReleaseMutex()
    $runnerMutex.Dispose()
}
exit $exitCode
