$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"

# Verified StickPNG CDN URLs
$chocolates = @(
    @{ Name = "cadbury creme egg"; Url = "https://assets.stickpng.com/images/587f943cb3935853619becdb.png" }
)

$success = @()
$failed = @()

foreach ($choc in $chocolates) {
    $name = $choc.Name
    $url = $choc.Url
    $outFile = Join-Path $outDir "$name.png"
    
    Write-Host "Downloading: $name"
    try {
        curl.exe -L -o $outFile -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" $url 2>&1 | Out-Null
        
        if (Test-Path $outFile) {
            $fileInfo = Get-Item $outFile
            if ($fileInfo.Length -gt 10000) {
                Write-Host "  OK: $name ($([math]::Round($fileInfo.Length/1024, 1)) KB)"
                $success += $name
            } else {
                Remove-Item $outFile -Force
                $failed += $name
                Write-Host "  FAILED (too small): $name"
            }
        }
    } catch {
        Write-Host "  FAILED: $name"
        $failed += $name
    }
    
    Start-Sleep -Seconds 1
}

Write-Host "`nSuccessful: $($success.Count)"
Write-Host "Failed: $($failed.Count)"
