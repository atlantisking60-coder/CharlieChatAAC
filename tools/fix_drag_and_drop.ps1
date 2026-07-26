# Maintenance script to fix drag and drop functionality in Charlie Chat
# This script ensures that Desktop and Web-Desktop use Draggable while Mobile uses LongPressDraggable.

$filePath = "lib/widgets/board_editor.dart"

if (Test-Path $filePath) {
    $content = Get-Content $filePath -Raw

    # Replace any line that defines isDesktop with the unified desktop expression
    $pattern = 'final\s+bool\s+isDesktop\s*=.*?;'
    $replacement = 'final bool isDesktop = (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);'

    $newContent = [regex]::Replace($content, $pattern, $replacement)

    if ($newContent -ne $content) {
        Set-Content -Path $filePath -Value $newContent -NoNewline
        Write-Host "Drag and drop logic has been synchronized for Desktop and Web." -ForegroundColor Green
    } else {
        Write-Host "No changes made; the expected pattern was not found." -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: Could not find $filePath" -ForegroundColor Red
    exit 1
}
