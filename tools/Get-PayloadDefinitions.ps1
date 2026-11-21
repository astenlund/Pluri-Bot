param([Parameter(Mandatory)][string]$Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Returns the payload text that defines the package's functions and constants, for dot-sourcing by release scripts and tests:
# everything from the payload begin marker to the start of the run-time state section.
$text = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true))
$begin = '### === POWERSHELL_PAYLOAD_' + 'BEGIN ==='
$start = $text.IndexOf($begin, [StringComparison]::Ordinal) + $begin.Length
$stop = $text.IndexOf('# Load and normalize persistent state', [StringComparison]::Ordinal)
if ($start -lt $begin.Length -or $stop -le $start) { throw "Payload definitions not found: $Path" }

return $text.Substring($start, $stop - $start)
