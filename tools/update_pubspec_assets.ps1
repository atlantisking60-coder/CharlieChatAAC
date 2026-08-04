# Update pubspec.yaml to list every directory under assets/ and lib/data/boards/
$ErrorActionPreference = "Stop"
$scriptDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$root = [System.IO.Directory]::GetParent($scriptDir).FullName
$pubspec = "$root\pubspec.yaml"

$dirs = [System.Collections.Generic.List[string]]::new()

function Add-Dirs($relPath) {
    $full = "$root\$($relPath.Replace('/', '\'))"
    if (Test-Path $full -PathType Container) {
        $dirs.Add("$relPath/".Replace('\', '/'))
        Get-ChildItem -Path $full -Recurse -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $p = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            $dirs.Add("$p/")
        }
    }
}

Add-Dirs "assets"

# All board JSON directories
Add-Dirs "lib/data/boards"

$uniqueDirs = $dirs | Sort-Object | Get-Unique

$lines = [System.IO.File]::ReadAllLines($pubspec)
$before = [System.Collections.Generic.List[string]]::new()
$inAssets = $false
foreach ($line in $lines) {
    if ($inAssets) { continue }
    if ($line -match '^\s*assets:\s*$') {
        $inAssets = $true
        $before.Add($line)
        break
    } else {
        $before.Add($line)
    }
}

$newLines = [System.Collections.Generic.List[string]]::new()
$newLines.AddRange($before)
foreach ($d in $uniqueDirs) {
    $newLines.Add("    - `"$d`"")
}

[System.IO.File]::WriteAllLines($pubspec, $newLines)
Write-Host "Updated $pubspec with $($uniqueDirs.Count) asset directories"
