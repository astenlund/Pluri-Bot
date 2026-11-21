param(
    [string]$TermsPath = (Join-Path $env:LOCALAPPDATA 'DLSS5-ADDER\release-records\sweep-terms.txt'),
    [string]$Root = (Join-Path $PSScriptRoot '..'),
    [string]$Revision = '',
    [string]$Range = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Sweeps for machine-specific and personal data before a push: the literal terms of the author's machine and account, kept outside the
# repository in -TermsPath, one per line and matched case-insensitively as whole words, and generic patterns for home paths, email addresses,
# tokens and keys. By default it sweeps the working tree's tracked and untracked unignored files; with -Revision, the files as that revision
# holds them; with -Range (such as origin/main..HEAD, or HEAD for a first push), every commit in the range: its message and each file it adds
# or changes, as that commit holds it, so text added in one unpushed commit and removed in a later one is still found. Lines naming a file in
# -Root's .privacy-exempt (path, then a tab and the reason) are reported as exempt, for content already public in published form. Any other
# hit fails the sweep, and so does any read that fails.
$Root = [IO.Path]::GetFullPath($Root)
if ($Revision.Length -gt 0 -and $Range.Length -gt 0) { throw 'Give -Revision or -Range, not both.' }
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
# Whole words only, so a term does not match inside a longer public name such as the GitHub owner's. Terms are reported by their position
# in the terms file, never by their text.
for ($index = 0; $index -lt $terms.Count; $index++) { $patterns['term ' + ($index + 1)] = '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($terms[$index]) + '(?![A-Za-z0-9])' }
$exempt = @{}
$exemptPath = Join-Path $Root '.privacy-exempt'
if (Test-Path -LiteralPath $exemptPath) {
    foreach ($line in [IO.File]::ReadAllLines($exemptPath)) { if ($line.Contains("`t")) { $exempt[$line.Split("`t")[0]] = $line.Split("`t", 2)[1] } }
}

function Read-GitText([string[]]$Arguments) {
    $output = @(& git -C $Root @Arguments)
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed, so the sweep did not cover it." }

    return $output -join "`n"
}

# Each item is a label, the file path that .privacy-exempt keys on (empty for a commit message), and a block that reads its text.
$items = [Collections.Generic.List[object]]::new()
if ($Range.Length -gt 0) {
    foreach ($commit in @((Read-GitText @('rev-list', '--reverse', $Range)).Split("`n", [StringSplitOptions]::RemoveEmptyEntries))) {
        $short = $commit.Substring(0, 12)
        $items.Add([pscustomobject]@{ Label = "$short message"; Path = ''; Read = { Read-GitText @('log', '-1', '--format=%B', $commit) }.GetNewClosure() })
        # A merge commit lists the files it changes against its first parent, so content only a merge introduces is still swept.
        foreach ($file in @((Read-GitText @('diff-tree', '--no-commit-id', '--root', '-r', '-m', '--first-parent', '--name-only', '--diff-filter=d', $commit)).Split("`n", [StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Unique)) {
            $items.Add([pscustomobject]@{ Label = "$short $file"; Path = $file; Read = { Read-GitText @('show', ($commit + ':' + $file)) }.GetNewClosure() })
        }
    }
}
elseif ($Revision.Length -gt 0) {
    foreach ($file in @((Read-GitText @('ls-tree', '-r', '--name-only', $Revision)).Split("`n", [StringSplitOptions]::RemoveEmptyEntries))) {
        $items.Add([pscustomobject]@{ Label = $file; Path = $file; Read = { Read-GitText @('show', ($Revision + ':' + $file)) }.GetNewClosure() })
    }
}
else {
    foreach ($file in @((Read-GitText @('ls-files', '--cached', '--others', '--exclude-standard')).Split("`n", [StringSplitOptions]::RemoveEmptyEntries))) {
        $items.Add([pscustomobject]@{ Label = $file; Path = $file; Read = { [IO.File]::ReadAllText((Join-Path $Root $file)) }.GetNewClosure() })
    }
}
$hits = 0
$exemptHits = 0
foreach ($item in $items) {
    $text = & $item.Read
    foreach ($value in $allowed) { $text = [regex]::Replace($text, [regex]::Escape($value), ' ', [Text.RegularExpressions.RegexOptions]::IgnoreCase) }
    foreach ($name in $patterns.Keys) {
        $matched = @([regex]::Matches($text, $patterns[$name]))
        # Addresses at the reserved example domains are fixture values.
        if ($name -ceq 'email address') { $matched = @($matched | Where-Object { $_.Value -notmatch '@example\.(com|org|net)$' }) }
        if ($matched.Count -eq 0) { continue }
        if ($item.Path.Length -gt 0 -and $exempt.ContainsKey($item.Path)) { $exemptHits += $matched.Count; "EXEMPT $($item.Label) ($name, $($matched.Count)): $($exempt[$item.Path])"; continue }
        $hits += $matched.Count
        "HIT $($item.Label) ($name, $($matched.Count))"
    }
}
"swept $($items.Count) items: $hits hits, $exemptHits exempt"
if ($hits -gt 0) { exit 1 }
