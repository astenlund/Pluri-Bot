param(
    [string]$TermsPath = (Join-Path $env:LOCALAPPDATA 'DLSS5-ADDER\release-records\sweep-terms.txt'),
    [string]$Root = (Join-Path $PSScriptRoot '..'),
    [string]$Revision = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Sweeps the tracked files for machine-specific and personal data before a push: the literal terms of the author's machine and account,
# kept outside the repository in -TermsPath, one per line and matched case-insensitively, and generic patterns for home paths, email
# addresses, tokens and keys. With -Revision it sweeps the files as that revision holds them, otherwise the working tree's tracked and
# untracked unignored files. Lines naming a file in -Root's .privacy-exempt (path, then a tab and the reason) are reported as exempt,
# for content already public in published form. Any other hit fails the sweep.
$Root = [IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath $TermsPath -PathType Leaf)) { throw "The sweep terms are missing: $TermsPath. The sweep cannot run without them." }
$lines = @([IO.File]::ReadAllLines($TermsPath) | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 -and -not $_.StartsWith('#', [StringComparison]::Ordinal) })
# An "allow: <text>" line names a value that is public by the author's decision, such as the commit address; it is removed before matching.
$allowed = @($lines | Where-Object { $_.StartsWith('allow:', [StringComparison]::Ordinal) } | ForEach-Object { $_.Substring(6).Trim() } | Where-Object { $_.Length -gt 0 })
$terms = @($lines | Where-Object { -not $_.StartsWith('allow:', [StringComparison]::Ordinal) })
if ($terms.Count -eq 0) { throw 'The sweep terms file holds no terms.' }
$patterns = [ordered]@{
    # A home folder other than the generic names tests use as fixture values.
    'home path' = '(?i)[a-z]:[\\/]+users[\\/]+(?!(<user>|public|default|s)[\\/])[^\\/\s''"`]+'
    'email address' = '(?i)\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b'
    'token or key' = '(gh[po]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|sk-ant-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
}
# Whole words only, so a term does not match inside a longer public name such as the GitHub owner's.
foreach ($term in $terms) { $patterns['term ' + $term.Substring(0, [Math]::Min(2, $term.Length)) + '...'] = '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($term) + '(?![A-Za-z0-9])' }
$exempt = @{}
$exemptPath = Join-Path $Root '.privacy-exempt'
if (Test-Path -LiteralPath $exemptPath) {
    foreach ($line in [IO.File]::ReadAllLines($exemptPath)) { if ($line.Contains("`t")) { $exempt[$line.Split("`t")[0]] = $line.Split("`t", 2)[1] } }
}
if ($Revision.Length -gt 0) { $files = @(& git -C $Root ls-tree -r --name-only $Revision) }
else { $files = @(& git -C $Root ls-files --cached --others --exclude-standard) }
if ($LASTEXITCODE -ne 0) { throw 'Git could not list the files to sweep.' }
$hits = 0
$exemptHits = 0
foreach ($file in $files) {
    if ($Revision.Length -gt 0) { $text = (& git -C $Root show ($Revision + ':' + $file)) -join "`n" }
    else { $text = [IO.File]::ReadAllText((Join-Path $Root $file)) }
    foreach ($value in $allowed) { $text = [regex]::Replace($text, [regex]::Escape($value), ' ', [Text.RegularExpressions.RegexOptions]::IgnoreCase) }
    foreach ($name in $patterns.Keys) {
        $count = [regex]::Matches($text, $patterns[$name]).Count
        if ($count -eq 0) { continue }
        # Addresses at the reserved example domains are fixture values.
        if ($name -ceq 'email address') {
            $count = @([regex]::Matches($text, $patterns[$name]) | Where-Object { $_.Value -notmatch '@example\.(com|org|net)$' }).Count
            if ($count -eq 0) { continue }
        }
        if ($exempt.ContainsKey($file)) { $exemptHits += $count; "EXEMPT $file ($name, $count): $($exempt[$file])"; continue }
        $hits += $count
        "HIT $file ($name, $count)"
    }
}
"swept $($files.Count) files: $hits hits, $exemptHits exempt"
if ($hits -gt 0) { exit 1 }
