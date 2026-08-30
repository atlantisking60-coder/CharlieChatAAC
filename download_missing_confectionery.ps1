$outDir = "C:\Users\Craig\Downloads\NEW CONFECTIONARY - CHECK THESE"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# All missing items that need downloading
$items = @(
    # === SWEETS (6 missing) ===
    @{ Name = "fruit gums"; WikiFile = "Fruit_Gums.jpg"; Category = "Sweets" },
    @{ Name = "randoms"; WikiFile = "Haribo_Randoms.jpg"; Category = "Sweets" },
    @{ Name = "jelly tots"; WikiFile = "Jelly_Tots.jpg"; Category = "Sweets" },
    @{ Name = "fun gums"; WikiFile = "Fun_Gums.jpg"; Category = "Sweets" },
    @{ Name = "fizzers"; WikiFile = "Fizzers_sweets.jpg"; Category = "Sweets" },
    @{ Name = "love hearts fizz"; WikiFile = "Love_Hearts_Fizz.jpg"; Category = "Sweets" },

    # === CHOCOLATES (28 missing) ===
    @{ Name = "cadbury dairy milk"; WikiFile = "Cadbury_Dairy_Milk.jpg"; Category = "Chocolates" },
    @{ Name = "cadbury fuse"; WikiFile = "Cadbury-Fuse-Split.jpg"; Category = "Chocolates" },
    @{ Name = "cadbury dairy milk oreo"; WikiFile = "Cadbury_Dairy_Milk_Oreo.jpg"; Category = "Chocolates" },
    @{ Name = "cadbury mini eggs"; WikiFile = "Cadbury_Mini_Eggs.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy"; WikiFile = "Galaxy_chocolate_bar.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy caramel"; WikiFile = "Galaxy_Caramel.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy ripple"; WikiFile = "Galaxy_Ripple.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy cookie crumble"; WikiFile = "Galaxy_Cookie_Crumble.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy smooth orange"; WikiFile = "Galaxy_Orange.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy minstrels"; WikiFile = "Galaxy_Minstrels.jpg"; Category = "Chocolates" },
    @{ Name = "galaxy counters"; WikiFile = "Galaxy_Counters.jpg"; Category = "Chocolates" },
    @{ Name = "kit kat chunky"; WikiFile = "KitKat_Chunky.jpg"; Category = "Chocolates" },
    @{ Name = "kit kat chunky peanut butter"; WikiFile = "KitKat_Chunky_Peanut_Butter.jpg"; Category = "Chocolates" },
    @{ Name = "kit kat dark chocolate"; WikiFile = "KitKat_Dark.jpg"; Category = "Chocolates" },
    @{ Name = "kit kat caramel"; WikiFile = "KitKat_Caramel.jpg"; Category = "Chocolates" },
    @{ Name = "maltesers buttons"; WikiFile = "Maltesers_Buttons.jpg"; Category = "Chocolates" },
    @{ Name = "maltesers truffles"; WikiFile = "Maltesers_Truffles.jpg"; Category = "Chocolates" },
    @{ Name = "aero"; WikiFile = "Aero-Bar-Split.jpg"; Category = "Chocolates" },
    @{ Name = "aero peppermint"; WikiFile = "Aero-Mint-Bar-Split.jpg"; Category = "Chocolates" },
    @{ Name = "aero orange"; WikiFile = "Aero-Orange-Split.jpg"; Category = "Chocolates" },
    @{ Name = "twix"; WikiFile = "Twix-broken.jpg"; Category = "Chocolates" },
    @{ Name = "mars bar"; WikiFile = "US-Mars-Bar-Split.jpg"; Category = "Chocolates" },
    @{ Name = "bounty"; WikiFile = "Bounty-Split.jpg"; Category = "Chocolates" },
    @{ Name = "topic"; WikiFile = "Topic-Bar-Split.jpg"; Category = "Chocolates" },
    @{ Name = "milkybar"; WikiFile = "Milkybar.jpg"; Category = "Chocolates" },
    @{ Name = "lion bar"; WikiFile = "Lion-Bar-Split.jpg"; Category = "Chocolates" },
    @{ Name = "toffee crisp"; WikiFile = "Toffee-Crisp-Split.jpg"; Category = "Chocolates" },
    @{ Name = "yorkie"; WikiFile = "Yorkie-Bar.jpg"; Category = "Chocolates" },

    # === CRISPS - FLAVOURS (3 missing) ===
    @{ Name = "prawn cocktail"; WikiFile = "Prawn_cocktail_crisps.jpg"; Category = "Crisps" },
    @{ Name = "smoky bacon"; WikiFile = "Smoky_bacon_crisps.jpg"; Category = "Crisps" },
    @{ Name = "salt and pepper"; WikiFile = "Salt_and_pepper_crisps.jpg"; Category = "Crisps" },

    # === CRISPS - BRANDS (21 missing) ===
    @{ Name = "walkers"; WikiFile = "Walkers_crisps.jpg"; Category = "Crisps" },
    @{ Name = "hula hoops"; WikiFile = "Hula_Hoops.jpg"; Category = "Crisps" },
    @{ Name = "space raiders"; WikiFile = "Space_Raiders.jpg"; Category = "Crisps" },
    @{ Name = "frazzles"; WikiFile = "Frazzles.jpg"; Category = "Crisps" },
    @{ Name = "discos"; WikiFile = "Discos_crisps.jpg"; Category = "Crisps" },
    @{ Name = "kettle chips"; WikiFile = "Kettle_Chips.jpg"; Category = "Crisps" },
    @{ Name = "seabrook's"; WikiFile = "Seabrook_crisps.jpg"; Category = "Crisps" },
    @{ Name = "tyrrells"; WikiFile = "Tyrrells_crisps.jpg"; Category = "Crisps" },
    @{ Name = "doritos"; WikiFile = "Doritos.jpg"; Category = "Crisps" },
    @{ Name = "chipsticks"; WikiFile = "Chipsticks.jpg"; Category = "Crisps" },
    @{ Name = "golden wonder"; WikiFile = "Golden_Wonder.jpg"; Category = "Crisps" },
    @{ Name = "monster claws"; WikiFile = "Monster_Claws.jpg"; Category = "Crisps" },
    @{ Name = "sunbites"; WikiFile = "Sunbites.jpg"; Category = "Crisps" },
    @{ Name = "bugles"; WikiFile = "Bugles_snack.jpg"; Category = "Crisps" },
    @{ Name = "mackie's"; WikiFile = "Mackies_crisps.jpg"; Category = "Crisps" },
    @{ Name = "manomasa"; WikiFile = "Manomasa.jpg"; Category = "Crisps" },
    @{ Name = "torres"; WikiFile = "Torres_crisps.jpg"; Category = "Crisps" },
    @{ Name = "tortilla"; WikiFile = "Tortilla_chips.jpg"; Category = "Crisps" },
    @{ Name = "prawn crackers"; WikiFile = "Prawn_crackers.jpg"; Category = "Crisps" },
    @{ Name = "coop"; WikiFile = "Coop_crisps.jpg"; Category = "Crisps" },
    @{ Name = "seabrook's loaded"; WikiFile = "Seabrook_Loaded.jpg"; Category = "Crisps" }
)

$success = @()
$failed = @()
$skipped = @()

foreach ($item in $items) {
    $name = $item.Name
    $wikiFile = $item.WikiFile
    $category = $item.Category
    $outFile = Join-Path $outDir "$name.png"
    
    # Skip if already downloaded and valid
    if (Test-Path $outFile) {
        $fi = Get-Item $outFile
        if ($fi.Length -gt 1000) {
            Write-Host "SKIP (exists): $name"
            $skipped += $name
            continue
        }
    }
    
    # Try Wikimedia API with exact filename first
    $encodedFile = [System.Uri]::EscapeDataString("File:$wikiFile")
    $apiUrl = "https://commons.wikimedia.org/w/api.php?action=query&titles=$encodedFile&prop=imageinfo&iiprop=url&iiurlwidth=800&format=json"
    
    Write-Host "Getting URL for: $name ($category)"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "ConfectioneryDownloader/1.0 (educational; mailto:user@example.com)")
        $json = $webClient.DownloadString($apiUrl)
        
        $data = $json | ConvertFrom-Json
        $pages = $data.query.pages
        $pageId = $pages.PSObject.Properties.Name | Select-Object -First 1
        
        # Check if page exists (not -1)
        if ($pageId -eq "-1") {
            Write-Host "  Page not found for: $name (tried $wikiFile)"
            # Try search-based fallback
            $searchQuery = [System.Uri]::EscapeDataString($name)
            $searchUrl = "https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=$searchQuery&srnamespace=6&srlimit=1&format=json"
            Start-Sleep -Seconds 2
            $searchJson = $webClient.DownloadString($searchUrl)
            $searchData = $searchJson | ConvertFrom-Json
            if ($searchData.query.search.Count -gt 0) {
                $foundTitle = $searchData.query.search[0].title
                $encodedFound = [System.Uri]::EscapeDataString($foundTitle)
                $apiUrl = "https://commons.wikimedia.org/w/api.php?action=query&titles=$encodedFound&prop=imageinfo&iiprop=url&iiurlwidth=800&format=json"
                Start-Sleep -Seconds 2
                $json = $webClient.DownloadString($apiUrl)
                $data = $json | ConvertFrom-Json
                $pages = $data.query.pages
                $pageId = $pages.PSObject.Properties.Name | Select-Object -First 1
                Write-Host "  Found via search: $foundTitle"
            } else {
                Write-Host "  No search results for: $name"
                $failed += $name
                continue
            }
        }
        
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
Write-Host "Downloaded: $($success.Count)"
Write-Host "Skipped (already existed): $($skipped.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Failed items:"
    $failed | ForEach-Object { Write-Host "  - $_" }
}
