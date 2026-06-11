# Repair: remove the mojibake tour-key block (inserted by an ANSI-parsed run
# of add_tour_l10n.ps1) from each arb, re-encode the insert script with a BOM
# so PowerShell 5.1 parses it as UTF-8, then re-run it.
param([Parameter(Mandatory=$true)][string]$RepoRoot)

$dir = Join-Path $RepoRoot "lib\l10n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

# 1) Strip the inserted block (starts with tourTryIt, ends with guideReplayTour)
foreach ($file in Get-ChildItem $dir -Filter *.arb) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $start = -1; $end = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($start -eq -1 -and $lines[$i] -match '"tourTryIt"') { $start = $i }
        if ($lines[$i] -match '"guideReplayTour"') { $end = $i; break }
    }
    if ($start -eq -1 -or $end -eq -1) { Write-Output "SKIP $($file.Name) (block not found)"; continue }
    $newLines = @($lines[0..($start-1)]) + @($lines[($end+1)..($lines.Count-1)])
    [System.IO.File]::WriteAllLines($file.FullName, $newLines, $utf8NoBom)
    Write-Output "STRIPPED $($file.Name) (lines $start..$end)"
}

# 2) Re-encode the insert script with a UTF-8 BOM (PS 5.1 needs it)
$script = Join-Path $RepoRoot "scripts\add_tour_l10n.ps1"
$content = [System.IO.File]::ReadAllText($script, $utf8NoBom)
[System.IO.File]::WriteAllText($script, $content, $utf8Bom)
Write-Output "RE-ENCODED add_tour_l10n.ps1 with BOM"

# 3) Re-run the insert
& $script
