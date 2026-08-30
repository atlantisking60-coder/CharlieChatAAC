$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$chocolates = @{
    "cadbury dairy milk" = @(
        "https://upload.wikimedia.org/wikipedia/commons/a/a0/Cadbury_Dairy_Milk.jpg"
    )
    "cadbury dairy milk caramel" = @(
        "https://upload.wikimedia.org/wikipedia/commons/a/af/Cadbury-Dairy-Milk-Caramel-Bar.jpg"
    )
    "cadbury twirl" = @(
        "https://upload.wikimedia.org/wikipedia/commons/7/71/Cadbury-Twirl-Split.jpg"
    )
    "cadbury wispa" = @(
        "https://upload.wikimedia.org/wikipedia/commons/2/2d/Wispa-Split.jpg"
    )
    "cadbury crunchie" = @(
        "https://upload.wikimedia.org/wikipedia/commons/2/29/Cadbury-Crunchie-Split.jpg"
    )
    "cadbury flake" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/4b/Cadbury-Flake-Split.jpg"
    )
    "cadbury boost" = @(
        "https://upload.wikimedia.org/wikipedia/commons/9/96/Boost_halves.JPG"
    )
    "cadbury picnic" = @(
        "https://upload.wikimedia.org/wikipedia/commons/a/af/Cadbury-Picnic-Split.jpg"
    )
    "cadbury curly wurly" = @(
        "https://upload.wikimedia.org/wikipedia/commons/b/b7/Curly-Wurly-Split.jpg"
    )
    "cadbury double decker" = @(
        "https://upload.wikimedia.org/wikipedia/commons/d/d0/Cadbury-Double-Decker-Split.jpg"
    )
    "cadbury timeout" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Time-Out-Split.jpg"
    )
    "cadbury starbar" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/4b/Cadbury-Starbar-Split.jpg"
    )
    "cadbury fuse" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Cadbury-Fuse-Split.jpg"
    )
    "cadbury dairy milk whole nut" = @(
        "https://upload.wikimedia.org/wikipedia/commons/0/0b/Cadbury-Dairy-Milk-Whole-Nut-Split.jpg"
    )
    "cadbury dairy milk fruit and nut" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/42/Cadbury-Dairy-Milk-Fruit-Nut-Split.jpg"
    )
    "cadbury dairy milk oreo" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5d/Cadbury_Dairy_Milk_Oreo.jpg"
    )
    "cadbury creme egg" = @(
        "https://upload.wikimedia.org/wikipedia/commons/e/e4/Cadbury-Creme-Egg-Whole-%26-Split.jpg"
    )
    "cadbury mini eggs" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/49/Cadbury_minieggs_logo.png"
    )
    "cadbury heroes" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Cadbury-Heroes-Tub.jpg"
    )
    "cadbury roses" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Cadbury-Roses-Tub.jpg"
    )
    "galaxy" = @(
        "https://upload.wikimedia.org/wikipedia/commons/0/0b/Galaxy_Milk_Chocolate_bar.jpg"
    )
    "galaxy caramel" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Caramel.jpg"
    )
    "galaxy ripple" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Ripple.jpg"
    )
    "galaxy cookie crumble" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Cookie_Crumble.jpg"
    )
    "galaxy smooth orange" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Smooth_Orange.jpg"
    )
    "galaxy minstrels" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Minstrels.jpg"
    )
    "galaxy counters" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Counters.jpg"
    )
    "galaxy truffles" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Galaxy_Truffles.jpg"
    )
    "kit kat" = @(
        "https://upload.wikimedia.org/wikipedia/commons/d/dd/KitKat.jpg"
    )
    "kit kat chunky" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Kit_Kat_Chunky.jpg"
    )
    "kit kat chunky peanut butter" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Kit_Kat_Chunky_Peanut_Butter.jpg"
    )
    "kit kat dark chocolate" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Kit_Kat_Dark.jpg"
    )
    "kit kat caramel" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Kit_Kat_Caramel.jpg"
    )
    "maltesers" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/48/Maltesers-Pile-and-Split.jpg"
    )
    "maltesers buttons" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Maltesers_Buttons.jpg"
    )
    "maltesers truffles" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Maltesers_Truffles.jpg"
    )
    "aero" = @(
        "https://upload.wikimedia.org/wikipedia/commons/3/37/Aero-Bar-Split.jpg"
    )
    "aero peppermint" = @(
        "https://upload.wikimedia.org/wikipedia/commons/e/ef/Aero-Mint-Bar-Split.jpg"
    )
    "aero orange" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Aero-Orange-Split.jpg"
    )
    "twix" = @(
        "https://upload.wikimedia.org/wikipedia/commons/e/e3/Twix-broken.jpg"
    )
    "snickers" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/57/Snickers-broken.JPG"
    )
    "mars bar" = @(
        "https://upload.wikimedia.org/wikipedia/commons/6/6a/US-Mars-Bar-Split.jpg"
    )
    "bounty" = @(
        "https://upload.wikimedia.org/wikipedia/commons/1/1a/Bounty-Split.jpg"
    )
    "topic" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/54/Topic-Bar-Split.jpg"
    )
    "milky way" = @(
        "https://upload.wikimedia.org/wikipedia/commons/d/d3/Milky-Way-Bars-USUK-Split.jpg"
    )
    "milkybar" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Milkybar.jpg"
    )
    "lion bar" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/4c/Lion-Bar-Split.jpg"
    )
    "toffee crisp" = @(
        "https://upload.wikimedia.org/wikipedia/commons/4/49/Toffee-Crisp-Split.jpg"
    )
    "rolo" = @(
        "https://upload.wikimedia.org/wikipedia/commons/5/5f/Rolo-Candies-US.jpg"
    )
    "yorkie" = @(
        "https://upload.wikimedia.org/wikipedia/commons/a/a7/Yorkie-Bar.jpg"
    )
}

$success = @()
$failed = @()

foreach ($name in $chocolates.Keys) {
    $outFile = Join-Path $outDir "$name.png"
    $downloaded = $false
    
    foreach ($url in $chocolates[$name]) {
        try {
            Write-Host "Downloading: $name"
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            $webClient.DownloadFile($url, $outFile)
            
            $fileInfo = Get-Item $outFile
            if ($fileInfo.Length -gt 1000) {
                Write-Host "  OK: $name ($([math]::Round($fileInfo.Length/1024, 1)) KB)"
                $success += $name
                $downloaded = $true
                break
            } else {
                Remove-Item $outFile -Force
                Write-Host "  Too small, trying next URL..."
            }
        } catch {
            Write-Host "  Failed: $($_.Exception.Message)"
            if (Test-Path $outFile) { Remove-Item $outFile -Force }
        }
    }
    
    if (!$downloaded) {
        $failed += $name
        Write-Host "  FAILED: $name"
    }
}

Write-Host "`n=== RESULTS ==="
Write-Host "Successful: $($success.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Failed items:"
    $failed | ForEach-Object { Write-Host "  - $_" }
}
