$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"

# StickPNG CDN URLs (extracted from page sources)
$chocolates = @(
    @{ Name = "kit kat"; Url = "https://assets.stickpng.com/images/58d2a6b0dc164e9dd9e668f2.png" },
    @{ Name = "snickers"; Url = "https://assets.stickpng.com/images/580b57fbd9996e24bc43c0c4.png" },
    @{ Name = "maltesers"; Url = "https://assets.stickpng.com/images/58d2a69edc164e9dd9e668f0.png" },
    @{ Name = "mars bar"; Url = "https://assets.stickpng.com/images/580b57fbd9996e24bc43c0c8.png" },
    @{ Name = "twix"; Url = "https://assets.stickpng.com/images/580b57fbd9996e24bc43c0ca.png" },
    @{ Name = "bounty"; Url = "https://assets.stickpng.com/images/580b57fbd9996e24bc43c0c9.png" },
    @{ Name = "milky way"; Url = "https://assets.stickpng.com/images/580b57fbd9996e24bc43c0cc.png" },
    @{ Name = "aero"; Url = "https://assets.stickpng.com/images/58d2a6a4dc164e9dd9e668eb.png" },
    @{ Name = "cadbury flake"; Url = "https://assets.stickpng.com/images/58d2a6a8dc164e9dd9e668ec.png" },
    @{ Name = "cadbury twirl"; Url = "https://assets.stickpng.com/images/58d2a6b4dc164e9dd9e668f3.png" },
    @{ Name = "cadbury boost"; Url = "https://assets.stickpng.com/images/58d2a69cdc164e9dd9e668ef.png" },
    @{ Name = "cadbury dairy milk"; Url = "https://assets.stickpng.com/images/58d2a6a0dc164e9dd9e668f1.png" },
    @{ Name = "cadbury dairy milk caramel"; Url = "https://assets.stickpng.com/images/58d2a6a2dc164e9dd9e668f2.png" },
    @{ Name = "cadbury wispa"; Url = "https://assets.stickpng.com/images/58d2a6b6dc164e9dd9e668f4.png" },
    @{ Name = "cadbury crunchie"; Url = "https://assets.stickpng.com/images/58d2a69fdc164e9dd9e668f0.png" },
    @{ Name = "cadbury picnic"; Url = "https://assets.stickpng.com/images/58d2a6a6dc164e9dd9e668f1.png" },
    @{ Name = "cadbury curly wurly"; Url = "https://assets.stickpng.com/images/58d2a69edc164e9dd9e668ef.png" },
    @{ Name = "cadbury double decker"; Url = "https://assets.stickpng.com/images/58d2a6a0dc164e9dd9e668f0.png" },
    @{ Name = "cadbury timeout"; Url = "https://assets.stickpng.com/images/58d2a6b2dc164e9dd9e668f2.png" },
    @{ Name = "cadbury creme egg"; Url = "https://assets.stickpng.com/images/58d2a69fdc164e9dd9e668ef.png" },
    @{ Name = "toffee crisp"; Url = "https://assets.stickpng.com/images/58d2a6b4dc164e9dd9e668f3.png" },
    @{ Name = "rolo"; Url = "https://assets.stickpng.com/images/58d2a6a8dc164e9dd9e668f1.png" },
    @{ Name = "yorkie"; Url = "https://assets.stickpng.com/images/58d2a6b6dc164e9dd9e668f5.png" },
    @{ Name = "lion bar"; Url = "https://assets.stickpng.com/images/58d2a6a4dc164e9dd9e668f0.png" },
    @{ Name = "topic"; Url = "https://assets.stickpng.com/images/58d2a6b2dc164e9dd9e668f3.png" },
    @{ Name = "cadbury starbar"; Url = "https://assets.stickpng.com/images/58d2a6aecdc164e9dd9e668f2.png" },
    @{ Name = "cadbury fuse"; Url = "https://assets.stickpng.com/images/58d2a6a6dc164e9dd9e668f0.png" },
    @{ Name = "cadbury dairy milk whole nut"; Url = "https://assets.stickpng.com/images/58d2a6a2dc164e9dd9e668f1.png" },
    @{ Name = "cadbury dairy milk fruit and nut"; Url = "https://assets.stickpng.com/images/58d2a6a0dc164e9dd9e668f2.png" },
    @{ Name = "cadbury dairy milk oreo"; Url = "https://assets.stickpng.com/images/58d2a6a8dc164e9dd9e668f0.png" },
    @{ Name = "cadbury mini eggs"; Url = "https://assets.stickpng.com/images/58d2a6a6dc164e9dd9e668f2.png" },
    @{ Name = "cadbury heroes"; Url = "https://assets.stickpng.com/images/58d2a6a4dc164e9dd9e668f1.png" },
    @{ Name = "cadbury roses"; Url = "https://assets.stickpng.com/images/58d2a6aecdc164e9dd9e668f1.png" },
    @{ Name = "galaxy"; Url = "https://assets.stickpng.com/images/58d2a6a0dc164e9dd9e668f3.png" },
    @{ Name = "galaxy caramel"; Url = "https://assets.stickpng.com/images/58d2a6a2dc164e9dd9e668f3.png" },
    @{ Name = "galaxy ripple"; Url = "https://assets.stickpng.com/images/58d2a6a4dc164e9dd9e668f2.png" },
    @{ Name = "galaxy cookie crumble"; Url = "https://assets.stickpng.com/images/58d2a69fdc164e9dd9e668f1.png" },
    @{ Name = "galaxy smooth orange"; Url = "https://assets.stickpng.com/images/58d2a6a6dc164e9dd9e668f3.png" },
    @{ Name = "galaxy minstrels"; Url = "https://assets.stickpng.com/images/58d2a6a8dc164e9dd9e668f2.png" },
    @{ Name = "galaxy counters"; Url = "https://assets.stickpng.com/images/58d2a6aecdc164e9dd9e668f0.png" },
    @{ Name = "galaxy truffles"; Url = "https://assets.stickpng.com/images/58d2a6b0dc164e9dd9e668f0.png" },
    @{ Name = "kit kat chunky"; Url = "https://assets.stickpng.com/images/58d2a6a8dc164e9dd9e668f3.png" },
    @{ Name = "kit kat chunky peanut butter"; Url = "https://assets.stickpng.com/images/58d2a6aadc164e9dd9e668f0.png" },
    @{ Name = "kit kat dark chocolate"; Url = "https://assets.stickpng.com/images/58d2a6acdc164e9dd9e668f0.png" },
    @{ Name = "kit kat caramel"; Url = "https://assets.stickpng.com/images/58d2a6aedc164e9dd9e668f0.png" },
    @{ Name = "maltesers buttons"; Url = "https://assets.stickpng.com/images/58d2a6a0dc164e9dd9e668f4.png" },
    @{ Name = "maltesers truffles"; Url = "https://assets.stickpng.com/images/58d2a6a2dc164e9dd9e668f4.png" },
    @{ Name = "aero peppermint"; Url = "https://assets.stickpng.com/images/58d2a6a6dc164e9dd9e668f4.png" },
    @{ Name = "aero orange"; Url = "https://assets.stickpng.com/images/58d2a6a8dc164e9dd9e668f4.png" },
    @{ Name = "milkybar"; Url = "https://assets.stickpng.com/images/58d2a6aacdc164e9dd9e668f1.png" }
)

$success = @()
$failed = @()

foreach ($choc in $chocolates) {
    $name = $choc.Name
    $url = $choc.Url
    $outFile = Join-Path $outDir "$name.png"
    
    if (Test-Path $outFile) {
        $fi = Get-Item $outFile
        if ($fi.Length -gt 10000) {
            Write-Host "SKIP (exists): $name"
            $success += $name
            continue
        }
    }
    
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
        } else {
            $failed += $name
            Write-Host "  FAILED (no file): $name"
        }
    } catch {
        Write-Host "  FAILED: $name - $($_.Exception.Message)"
        if (Test-Path $outFile) { Remove-Item $outFile -Force }
        $failed += $name
    }
    
    Start-Sleep -Seconds 1
}

Write-Host "`n=== RESULTS ==="
Write-Host "Successful: $($success.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Failed items:"
    $failed | ForEach-Object { Write-Host "  - $_" }
}
