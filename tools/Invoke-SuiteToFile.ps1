param(
    [Parameter(Mandatory=$true)][string]$UpdaterPath,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$Suite = (Join-Path $PSScriptRoot '..\tests\Test-PluriBotBase.ps1')
)

# A prompt for input fails instead of waiting forever on the hidden desktop.
& pwsh -NoProfile -NonInteractive -File $Suite -UpdaterPath $UpdaterPath *> $OutputPath
exit $LASTEXITCODE
