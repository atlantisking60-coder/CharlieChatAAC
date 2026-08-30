$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# Direct full-size URLs from Wikimedia Commons (verified)
$chocolates = @(
    @{ Name = "cadbury dairy milk"; Url = "https://upload.wikimedia.org/wikipedia/commons/9/96/Cadbury_Dairy_Milk.jpg" },
    @{ Name = "cadbury dairy milk caramel"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5e/Cadbury-Dairy-Milk-Caramel-Bar.jpg" },
    @{ Name = "cadbury twirl"; Url = "https://upload.wikimedia.org/wikipedia/commons/7/71/Cadbury-Twirl-Split.jpg" },
    @{ Name = "cadbury wispa"; Url = "https://upload.wikimedia.org/wikipedia/commons/2/2d/Wispa-Split.jpg" },
    @{ Name = "cadbury crunchie"; Url = "https://upload.wikimedia.org/wikipedia/commons/2/29/Cadbury-Crunchie-Split.jpg" },
    @{ Name = "cadbury flake"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/4b/Cadbury-Flake-Split.jpg" },
    @{ Name = "cadbury boost"; Url = "https://upload.wikimedia.org/wikipedia/commons/9/96/Boost_halves.JPG" },
    @{ Name = "cadbury picnic"; Url = "https://upload.wikimedia.org/wikipedia/commons/a/af/Cadbury-Picnic-Split.jpg" },
    @{ Name = "cadbury curly wurly"; Url = "https://upload.wikimedia.org/wikipedia/commons/b/b7/Curly-Wurly-Split.jpg" },
    @{ Name = "cadbury double decker"; Url = "https://upload.wikimedia.org/wikipedia/commons/d/d0/Cadbury-Double-Decker-Split.jpg" },
    @{ Name = "cadbury timeout"; Url = "https://upload.wikimedia.org/wikipedia/commons/a/ae/Time-Out-Split.jpg" },
    @{ Name = "cadbury dairy milk oreo"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5d/Cadbury_Dairy_Milk_Oreo.jpg" },
    @{ Name = "cadbury creme egg"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/e4/Cadbury-Creme-Egg-Whole-%26-Split.jpg" },
    @{ Name = "kit kat"; Url = "https://upload.wikimedia.org/wikipedia/commons/d/dd/KitKat.jpg" },
    @{ Name = "maltesers"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/48/Maltesers-Pile-and-Split.jpg" },
    @{ Name = "aero"; Url = "https://upload.wikimedia.org/wikipedia/commons/a/a3/Aero-Bar-Split.jpg" },
    @{ Name = "aero peppermint"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/ef/Aero-Mint-Bar-Split.jpg" },
    @{ Name = "twix"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/e3/Twix-broken.jpg" },
    @{ Name = "snickers"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/57/Snickers-broken.JPG" },
    @{ Name = "mars bar"; Url = "https://upload.wikimedia.org/wikipedia/commons/6/6a/US-Mars-Bar-Split.jpg" },
    @{ Name = "bounty"; Url = "https://upload.wikimedia.org/wikipedia/commons/3/3f/Bounty-Split.jpg" },
    @{ Name = "topic"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/54/Topic-Bar-Split.jpg" },
    @{ Name = "milky way"; Url = "https://upload.wikimedia.org/wikipedia/commons/8/8f/Milky-Way-Bars-USUK-Split.jpg" },
    @{ Name = "lion bar"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/e7/Lion-Bar-Split.jpg" },
    @{ Name = "toffee crisp"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/49/Toffee-Crisp-Split.jpg" },
    @{ Name = "rolo"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/e7/Rolo-Candies-US.jpg" },
    @{ Name = "yorkie"; Url = "https://upload.wikimedia.org/wikipedia/commons/a/a7/Yorkie-Bar.jpg" }
)

$success = @()
$failed = @()

foreach ($choc in $chocolates) {
    $name = $choc.Name
    $url = $choc.Url
    $outFile = Join-Path $outDir "$name.png"
    
    if (Test-Path $outFile) {
        $fi = Get-Item $outFile
        if ($fi.Length -gt 1000) {
            Write-Host "SKIP (exists): $name"
            $success += $name
            continue
        }
    }
    
    Write-Host "Downloading: $name"
    try {
        $headers = @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            "Accept" = "image/webp,image/apng,image/*,*/*;q=0.8"
            "Accept-Language" = "en-US,en;q=0.9"
            "Referer" = "https://commons.wikimedia.org/"
        }
        Invoke-WebRequest -Uri $url -OutFile $outFile -Headers $headers -UseBasicParsing
        
        $fileInfo = Get-Item $outFile
        if ($fileInfo.Length -gt 1000) {
            Write-Host "  OK: $name ($([math]::Round($fileInfo.Length/1024, 1)) KB)"
            $success += $name
        } else {
            Remove-Item $outFile -Force
            $failed += $name
            Write-Host "  FAILED (too small): $name"
        }
    } catch {
        Write-Host "  FAILED: $name - $($_.Exception.Message)"
        if (Test-Path $outFile) { Remove-Item $outFile -Force }
        $failed += $name
    }
    
    Start-Sleep -Seconds 3
}

Write-Host "`n=== RESULTS ==="
Write-Host "Successful: $($success.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Failed items:"
    $failed | ForEach-Object { Write-Host "  - $_" }
}
