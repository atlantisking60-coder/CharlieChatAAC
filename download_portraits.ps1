# Final retry for last 4 remaining portraits
$baseDir = "C:\Users\Craig\Downloads\Charlie Chat\assets\Legends\Real Life Heroes"

$lastPeople = @(
    @{Name="rafael nadal"; WikiPage="Rafael_Nadal"; Category="Sporting Icons"},
    @{Name="carl lewis"; WikiPage="Carl_Lewis"; Category="Sporting Icons"},
    @{Name="valentino rossi"; WikiPage="Valentino_Rossi"; Category="Sporting Icons"},
    @{Name="katie ledecky"; WikiPage="Katie_Ledecky"; Category="Sporting Icons"}
)

function Download-Portrait {
    param(
        [string]$Name,
        [string]$WikiPage,
        [string]$Category
    )
    
    $dir = "$baseDir\$Category"
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    
    $outputFile = "$dir\$Name.png"
    
    $apiUrl = "https://en.wikipedia.org/w/api.php?action=query&titles=$WikiPage&prop=pageimages&format=json&pithumbsize=500"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $pages = $response.query.pages
        $pageId = $pages.PSObject.Properties.Value
        $imageUrl = $pageId.thumbnail.source
        
        if ($imageUrl) {
            Invoke-WebRequest -Uri $imageUrl -OutFile $outputFile -UseBasicParsing
            Write-Host "Downloaded: $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "No image found for: $Name" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed: $Name" -ForegroundColor Red
    }
    
    return $false
}

Write-Host ""
Write-Host "=== FINAL RETRY ===" -ForegroundColor Yellow
foreach ($person in $lastPeople) {
    Download-Portrait -Name $person.Name -WikiPage $person.WikiPage -Category $person.Category
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Cyan
