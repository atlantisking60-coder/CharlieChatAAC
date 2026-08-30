$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$chocolates = @(
    @{ Name = "cadbury dairy milk"; File = "Cadbury_Dairy_Milk.jpg" },
    @{ Name = "cadbury dairy milk caramel"; File = "Cadbury-Dairy-Milk-Caramel-Bar.jpg" },
    @{ Name = "cadbury twirl"; File = "Cadbury-Twirl-Split.jpg" },
    @{ Name = "cadbury wispa"; File = "Wispa-Split.jpg" },
    @{ Name = "cadbury crunchie"; File = "Cadbury-Crunchie-Split.jpg" },
    @{ Name = "cadbury flake"; File = "Cadbury-Flake-Split.jpg" },
    @{ Name = "cadbury boost"; File = "Boost_halves.JPG" },
    @{ Name = "cadbury picnic"; File = "Cadbury-Picnic-Split.jpg" },
    @{ Name = "cadbury curly wurly"; File = "Curly-Wurly-Split.jpg" },
    @{ Name = "cadbury double decker"; File = "Cadbury-Double-Decker-Split.jpg" },
    @{ Name = "cadbury timeout"; File = "Time-Out-Split.jpg" },
    @{ Name = "cadbury starbar"; File = "Cadbury-Starbar-Split.jpg" },
    @{ Name = "cadbury fuse"; File = "Cadbury-Fuse-Split.jpg" },
    @{ Name = "cadbury dairy milk whole nut"; File = "Cadbury-Dairy-Milk-Whole-Nut-Split.jpg" },
    @{ Name = "cadbury dairy milk fruit and nut"; File = "Cadbury-Dairy-Milk-Fruit-Nut-Split.jpg" },
    @{ Name = "cadbury dairy milk oreo"; File = "Cadbury_Dairy_Milk_Oreo.jpg" },
    @{ Name = "cadbury creme egg"; File = "Cadbury-Creme-Egg-Whole-%26-Split.jpg" },
    @{ Name = "cadbury mini eggs"; File = "Cadbury_mini_eggs.jpg" },
    @{ Name = "cadbury heroes"; File = "Cadbury-Heroes.jpg" },
    @{ Name = "cadbury roses"; File = "Cadbury-Roses.jpg" },
    @{ Name = "galaxy"; File = "Galaxy-chocolate-bar.jpg" },
    @{ Name = "galaxy caramel"; File = "Galaxy_Caramel.jpg" },
    @{ Name = "galaxy ripple"; File = "Galaxy_Ripple.jpg" },
    @{ Name = "galaxy cookie crumble"; File = "Galaxy_Cookie_Crumble.jpg" },
    @{ Name = "galaxy smooth orange"; File = "Galaxy_Orange.jpg" },
    @{ Name = "galaxy minstrels"; File = "Galaxy_Minstrels.jpg" },
    @{ Name = "galaxy counters"; File = "Galaxy_Counters.jpg" },
    @{ Name = "galaxy truffles"; File = "Galaxy_Truffles.jpg" },
    @{ Name = "kit kat"; File = "KitKat.jpg" },
    @{ Name = "kit kat chunky"; File = "Kit_Kat_Chunky.jpg" },
    @{ Name = "kit kat chunky peanut butter"; File = "KitKat_Chunky_Peanut_Butter.jpg" },
    @{ Name = "kit kat dark chocolate"; File = "KitKat_Dark.jpg" },
    @{ Name = "kit kat caramel"; File = "KitKat_Caramel.jpg" },
    @{ Name = "maltesers"; File = "Maltesers-Pile-and-Split.jpg" },
    @{ Name = "maltesers buttons"; File = "Maltesers_Buttons.jpg" },
    @{ Name = "maltesers truffles"; File = "Maltesers_Truffles.jpg" },
    @{ Name = "aero"; File = "Aero-Bar-Split.jpg" },
    @{ Name = "aero peppermint"; File = "Aero-Mint-Bar-Split.jpg" },
    @{ Name = "aero orange"; File = "Aero-Orange-Split.jpg" },
    @{ Name = "twix"; File = "Twix-broken.jpg" },
    @{ Name = "snickers"; File = "Snickers-broken.JPG" },
    @{ Name = "mars bar"; File = "US-Mars-Bar-Split.jpg" },
    @{ Name = "bounty"; File = "Bounty-Split.jpg" },
    @{ Name = "topic"; File = "Topic-Bar-Split.jpg" },
    @{ Name = "milky way"; File = "Milky-Way-Bars-USUK-Split.jpg" },
    @{ Name = "milkybar"; File = "Milkybar.jpg" },
    @{ Name = "lion bar"; File = "Lion-Bar-Split.jpg" },
    @{ Name = "toffee crisp"; File = "Toffee-Crisp-Split.jpg" },
    @{ Name = "rolo"; File = "Rolo-Candies-US.jpg" },
    @{ Name = "yorkie"; File = "Yorkie-Bar.jpg" }
)

function Get-MD5($filename) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($filename)
    $hash = $md5.ComputeHash($bytes)
    return ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
}

$success = @()
$failed = @()

foreach ($choc in $chocolates) {
    $name = $choc.Name
    $file = $choc.File
    $outFile = Join-Path $outDir "$name.png"
    
    if (Test-Path $outFile) {
        $fi = Get-Item $outFile
        if ($fi.Length -gt 1000) {
            Write-Host "SKIP (exists): $name"
            $success += $name
            continue
        }
    }
    
    $hash = Get-MD5 $file
    $h1 = $hash.Substring(0, 1)
    $h2 = $hash.Substring(0, 2)
    $url = "https://upload.wikimedia.org/wikipedia/commons/thumb/$h1/$h2/$file/800px-$file"
    
    Write-Host "Downloading: $name"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "ChocolateDownloader/1.0 (educational; mailto:user@example.com)")
        $webClient.DownloadFile($url, $outFile)
        
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
