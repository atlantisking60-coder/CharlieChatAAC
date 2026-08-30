$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$chocolates = @(
    @{ Name = "cadbury dairy milk"; WikiFile = "Cadbury_Dairy_Milk.jpg" },
    @{ Name = "cadbury dairy milk caramel"; WikiFile = "Cadbury-Dairy-Milk-Caramel-Bar.jpg" },
    @{ Name = "cadbury twirl"; WikiFile = "Cadbury-Twirl-Split.jpg" },
    @{ Name = "cadbury wispa"; WikiFile = "Wispa-Split.jpg" },
    @{ Name = "cadbury crunchie"; WikiFile = "Cadbury-Crunchie-Split.jpg" },
    @{ Name = "cadbury flake"; WikiFile = "Cadbury-Flake-Split.jpg" },
    @{ Name = "cadbury boost"; WikiFile = "Boost_halves.JPG" },
    @{ Name = "cadbury picnic"; WikiFile = "Cadbury-Picnic-Split.jpg" },
    @{ Name = "cadbury curly wurly"; WikiFile = "Curly-Wurly-Split.jpg" },
    @{ Name = "cadbury double decker"; WikiFile = "Cadbury-Double-Decker-Split.jpg" },
    @{ Name = "cadbury timeout"; WikiFile = "Time-Out-Split.jpg" },
    @{ Name = "cadbury starbar"; WikiFile = "Cadbury-Starbar-Split.jpg" },
    @{ Name = "cadbury fuse"; WikiFile = "Cadbury-Fuse-Split.jpg" },
    @{ Name = "cadbury dairy milk whole nut"; WikiFile = "Cadbury-Dairy-Milk-Whole-Nut-Split.jpg" },
    @{ Name = "cadbury dairy milk fruit and nut"; WikiFile = "Cadbury-Dairy-Milk-Fruit-Nut-Split.jpg" },
    @{ Name = "cadbury dairy milk oreo"; WikiFile = "Cadbury_Dairy_Milk_Oreo.jpg" },
    @{ Name = "cadbury creme egg"; WikiFile = "Cadbury-Creme-Egg-Whole-&-Split.jpg" },
    @{ Name = "cadbury mini eggs"; WikiFile = "Cadbury_Mini_Eggs.jpg" },
    @{ Name = "cadbury heroes"; WikiFile = "Cadbury_Heroes.jpg" },
    @{ Name = "cadbury roses"; WikiFile = "Cadbury_Roses.jpg" },
    @{ Name = "galaxy"; WikiFile = "Galaxy_chocolate_bar.jpg" },
    @{ Name = "galaxy caramel"; WikiFile = "Galaxy_Caramel.jpg" },
    @{ Name = "galaxy ripple"; WikiFile = "Galaxy_Ripple.jpg" },
    @{ Name = "galaxy cookie crumble"; WikiFile = "Galaxy_Cookie_Crumble.jpg" },
    @{ Name = "galaxy smooth orange"; WikiFile = "Galaxy_Orange.jpg" },
    @{ Name = "galaxy minstrels"; WikiFile = "Galaxy_Minstrels.jpg" },
    @{ Name = "galaxy counters"; WikiFile = "Galaxy_Counters.jpg" },
    @{ Name = "galaxy truffles"; WikiFile = "Galaxy_Truffles.jpg" },
    @{ Name = "kit kat"; WikiFile = "KitKat.jpg" },
    @{ Name = "kit kat chunky"; WikiFile = "KitKat_Chunky.jpg" },
    @{ Name = "kit kat chunky peanut butter"; WikiFile = "KitKat_Chunky_Peanut_Butter.jpg" },
    @{ Name = "kit kat dark chocolate"; WikiFile = "KitKat_Dark.jpg" },
    @{ Name = "kit kat caramel"; WikiFile = "KitKat_Caramel.jpg" },
    @{ Name = "maltesers"; WikiFile = "Maltesers-Pile-and-Split.jpg" },
    @{ Name = "maltesers buttons"; WikiFile = "Maltesers_Buttons.jpg" },
    @{ Name = "maltesers truffles"; WikiFile = "Maltesers_Truffles.jpg" },
    @{ Name = "aero"; WikiFile = "Aero-Bar-Split.jpg" },
    @{ Name = "aero peppermint"; WikiFile = "Aero-Mint-Bar-Split.jpg" },
    @{ Name = "aero orange"; WikiFile = "Aero-Orange-Split.jpg" },
    @{ Name = "twix"; WikiFile = "Twix-broken.jpg" },
    @{ Name = "snickers"; WikiFile = "Snickers-broken.JPG" },
    @{ Name = "mars bar"; WikiFile = "US-Mars-Bar-Split.jpg" },
    @{ Name = "bounty"; WikiFile = "Bounty-Split.jpg" },
    @{ Name = "topic"; WikiFile = "Topic-Bar-Split.jpg" },
    @{ Name = "milky way"; WikiFile = "Milky-Way-Bars-USUK-Split.jpg" },
    @{ Name = "milkybar"; WikiFile = "Milkybar.jpg" },
    @{ Name = "lion bar"; WikiFile = "Lion-Bar-Split.jpg" },
    @{ Name = "toffee crisp"; WikiFile = "Toffee-Crisp-Split.jpg" },
    @{ Name = "rolo"; WikiFile = "Rolo-Candies-US.jpg" },
    @{ Name = "yorkie"; WikiFile = "Yorkie-Bar.jpg" }
)

$success = @()
$failed = @()

foreach ($choc in $chocolates) {
    $name = $choc.Name
    $wikiFile = $choc.WikiFile
    $outFile = Join-Path $outDir "$name.png"
    
    if (Test-Path $outFile) {
        $fi = Get-Item $outFile
        if ($fi.Length -gt 1000) {
            Write-Host "SKIP (exists): $name"
            $success += $name
            continue
        }
    }
    
    # Use Wikimedia API to get image URL
    $encodedFile = [System.Uri]::EscapeDataString("File:$wikiFile")
    $apiUrl = "https://commons.wikimedia.org/w/api.php?action=query&titles=$encodedFile&prop=imageinfo&iiprop=url&iiurlwidth=800&format=json"
    
    Write-Host "Getting URL for: $name"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "ChocolateDownloader/1.0 (educational; mailto:user@example.com)")
        $json = $webClient.DownloadString($apiUrl)
        
        # Parse JSON to get URL
        $data = $json | ConvertFrom-Json
        $pages = $data.query.pages
        $pageId = $pages.PSObject.Properties.Name | Select-Object -First 1
        $imageUrl = $pages.$pageId.imageinfo[0].thumburl
        
        if ([string]::IsNullOrEmpty($imageUrl)) {
            $imageUrl = $pages.$pageId.imageinfo[0].url
        }
        
        if ([string]::IsNullOrEmpty($imageUrl)) {
            Write-Host "  No URL found for: $name"
            $failed += $name
            continue
        }
        
        Write-Host "  URL: $imageUrl"
        Start-Sleep -Seconds 2
        
        $webClient.DownloadFile($imageUrl, $outFile)
        
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
