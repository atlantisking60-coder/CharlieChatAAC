param(
  [string]$BasePath = "C:\Users\Craig\Downloads\Charlie Chat"
)

$logPath = Join-Path $BasePath 'replace_ampersand.log'
if (Test-Path $logPath) { Remove-Item $logPath -Force }
Start-Transcript -Path $logPath -Force
$ErrorActionPreference = 'Continue'

try {
  Write-Host "Renaming files and directories with ' & ' in their names..."

  $items = Get-ChildItem -LiteralPath $BasePath -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match ' & ' } |
    Sort-Object FullName -Descending

  $renamed = 0
  $failedRename = @()
  foreach ($item in $items) {
    $newName = $item.Name -replace ' & ', ' and '
    Write-Host "  Rename: $($item.FullName) -> $newName"
    try {
      Rename-Item -LiteralPath $item.FullName -NewName $newName -ErrorAction Stop
      $renamed++
    } catch {
      Write-Warning "  Failed to rename $($item.FullName): $_"
      $failedRename += $item.FullName
    }
  }

  Write-Host "`nUpdating main project files..."

  $exts = @('.dart', '.yaml', '.yml', '.json')
  $excludeNames = @('temp_list.txt', 'tmp_count.txt', 'CASCADE PROMPTS TO DO.txt', 'CASCADE PROMPTS DONE - TO CHECK.txt')
  $utf8 = New-Object System.Text.UTF8Encoding($false)

  $files = Get-ChildItem -LiteralPath $BasePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $exts -contains $_.Extension -and ($_.Name -notin $excludeNames) }

  $updated = 0
  $failedUpdate = @()
  foreach ($file in $files) {
    $path = $file.FullName
    try {
      $content = [System.IO.File]::ReadAllText($path)
      $changed = $false
      if ($content -match ' & ') {
        $content = $content -replace ' & ', ' and '
        $changed = $true
      }
      if ($content -match 'Logos_And_Profile_Pics') {
        $content = $content -replace 'Logos_And_Profile_Pics', 'Logos and Profile Pics'
        $changed = $true
      }
      if ($changed) {
        Write-Host "  Update: $path"
        [System.IO.File]::WriteAllText($path, $content, $utf8)
        $updated++
      }
    } catch {
      Write-Warning "  Failed to update $path : $_"
      $failedUpdate += $path
    }
  }

  Write-Host "`nDone. Renamed $renamed, updated $updated."
  if ($failedRename.Count -gt 0) { Write-Warning "Renames failed: $($failedRename.Count)" }
  if ($failedUpdate.Count -gt 0) { Write-Warning "File updates failed: $($failedUpdate.Count)" }
  Write-Host "Full log saved to: $logPath"
} finally {
  Stop-Transcript
}

