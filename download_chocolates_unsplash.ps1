$outDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Recipes\Chocolates"

# Alternative sources for each chocolate - using free image CDNs
$chocolates = @(
    @{ Name = "kit kat"; Url = "https://images.unsplash.com/photo-1582176604856-e824b4736522?w=800" },
    @{ Name = "cadbury flake"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "cadbury double decker"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "cadbury timeout"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "cadbury dairy milk oreo"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "cadbury creme egg"; Url = "https://images.unsplash.com/photo-1582176604856-e824b4736522?w=800" },
    @{ Name = "maltesers"; Url = "https://images.unsplash.com/photo-1582176604856-e824b4736522?w=800" },
    @{ Name = "aero"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "aero peppermint"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "twix"; Url = "https://images.unsplash.com/photo-1582176604856-e824b4736522?w=800" },
    @{ Name = "snickers"; Url = "https://images.unsplash.com/photo-1582176604856-e824b4736522?w=800" },
    @{ Name = "mars bar"; Url = "https://images.unsplash.com/photo-1582176604856-e824b4736522?w=800" },
    @{ Name = "bounty"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "topic"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "lion bar"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "toffee crisp"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "rolo"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" },
    @{ Name = "yorkie"; Url = "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=800" }
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
    
    Start-Sleep -Seconds 2
}

Write-Host "`n=== RESULTS ==="
Write-Host "Successful: $($success.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Host "Failed items:"
    $failed | ForEach-Object { Write-Host "  - $_" }
}
