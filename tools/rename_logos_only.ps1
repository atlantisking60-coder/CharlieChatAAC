param(
  [string]$BasePath = "C:\Users\Craig\Downloads\Charlie Chat"
)

$logPath = Join-Path $BasePath 'rename_logos_only.log'
if (Test-Path $logPath) { Remove-Item $logPath -Force }
Start-Transcript -Path $logPath -Force

try {
  $source = Join-Path $BasePath 'assets\Logos & Profile Pics'
  $target = Join-Path $BasePath 'assets\Logos and Profile Pics'

  if (Test-Path -LiteralPath $source) {
    if (Test-Path -LiteralPath $target) {
      Write-Error "Destination already exists: $target"
    } else {
      Rename-Item -LiteralPath $source -NewName 'Logos and Profile Pics'
      Write-Host "Renamed 'Logos & Profile Pics' -> 'Logos and Profile Pics'"
    }
  } else {
    Write-Host "Source folder not found: $source"
  }

  Write-Host "Log saved to: $logPath"
} finally {
  Stop-Transcript
}
