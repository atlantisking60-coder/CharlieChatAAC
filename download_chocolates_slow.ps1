$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"

# All remaining chocolates to download
$chocolates = @(
    @{ Name = "cadbury flake"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/4b/Cadbury-Flake-Split.jpg" },
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
    @{ Name = "lion bar"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/e7/Lion-Bar-Split.jpg" },
    @{ Name = "toffee crisp"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/49/Toffee-Crisp-Split.jpg" },
    @{ Name = "rolo"; Url = "https://upload.wikimedia.org/wikipedia/commons/e/e7/Rolo-Candies-US.jpg" },
    @{ Name = "yorkie"; Url = "https://upload.wikimedia.org/wikipedia/commons/a/a7/Yorkie-Bar.jpg" },
    @{ Name = "cadbury starbar"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/4b/Starbar.jpg" },
    @{ Name = "cadbury fuse"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Fuse-bar.jpg" },
    @{ Name = "cadbury dairy milk whole nut"; Url = "https://upload.wikimedia.org/wikipedia/commons/0/0b/Cadbury_Dairy_Milk_Whole_Nut.jpg" },
    @{ Name = "cadbury dairy milk fruit and nut"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/42/Cadbury_Dairy_Milk_Fruit_and_Nut.jpg" },
    @{ Name = "cadbury mini eggs"; Url = "https://upload.wikimedia.org/wikipedia/commons/4/49/Cadbury_minieggs_logo.png" },
    @{ Name = "cadbury heroes"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Cadbury_Heroes.jpg" },
    @{ Name = "cadbury roses"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Cadbury_Roses.jpg" },
    @{ Name = "galaxy"; Url = "https://upload.wikimedia.org/wikipedia/commons/0/0b/Galaxy_Milk_Chocolate.jpg" },
    @{ Name = "galaxy caramel"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Caramel.jpg" },
    @{ Name = "galaxy ripple"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Ripple.jpg" },
    @{ Name = "galaxy cookie crumble"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Cookie_Crumble.jpg" },
    @{ Name = "galaxy smooth orange"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Orange.jpg" },
    @{ Name = "galaxy minstrels"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Minstrels.jpg" },
    @{ Name = "galaxy counters"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Counters.jpg" },
    @{ Name = "galaxy truffles"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Truffles.jpg" },
    @{ Name = "kit kat chunky"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/KitKat_Chunky.jpg" },
    @{ Name = "kit kat chunky peanut butter"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/KitKat_Chunky_PB.jpg" },
    @{ Name = "kit kat dark chocolate"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/KitKat_Dark.jpg" },
    @{ Name = "kit kat caramel"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/KitKat_Caramel.jpg" },
    @{ Name = "maltesers buttons"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Maltesers_Buttons.jpg" },
    @{ Name = "maltesers truffles"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Maltesers_Truffles.jpg" },
    @{ Name = "aero orange"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Aero_Orange.jpg" },
    @{ Name = "milkybar"; Url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Milkybar.jpg" }
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
        $headers = @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            "Accept" = "image/webp,image/apng,image/*,*/*;q=0.8"
            "Referer" = "https://commons.wikimedia.org/"
        }
        Invoke-WebRequest -Uri $url -OutFile $outFile -Headers $headers -UseBasicParsing
        
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
    
    Write-Host "  Waiting 15 seconds..."
    Start-Sleep -Seconds 15
}

Write-Host "`n=== RESULTS ==="
Write-Host "Successful: $($success.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Failed items:"
    $failed | ForEach-Object { Write-Host "  - $_" }
}
