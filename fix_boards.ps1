// Comprehensive Script to Fix Charlie Chat Board Issues

import os;
import json;
import shutil;

# Constants
CHARLIE_CHAT_ROOT = "C:/Users/Craig/Downloads/Charlie Chat";

function WalkDirectory($path, $indent = 0) {
    $items = Get-ChildItem -LiteralPath $path;
    foreach ($item in $items) {
        $indentStr = " " * $indent;
        if ($item.PSIsContainer) {
            Write-Host "${indentStr}$($item.Name)/";
            WalkDirectory -Path $item.FullName -indent ($indent + 2);
        } else {
            Write-Host "${indentStr}$($item.Name)";
        }
    }
}

function AnalyzeStructure($path, $indent = 0) {
    $indentStr = " " * $indent;
    $items = Get-ChildItem -LiteralPath $path;
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Write-Host "${indentStr}$($item.Name)/";
            AnalyzeStructure -Path $item.FullName -indent ($indent + 2);
        } else {
            $ext = [System.IO.Path]::GetExtension($item.Name).ToLower();
            if ($ext -eq ".json") {
                try {
                    $jsonPath = $item.FullName;
                    $jsonContent = Get-Content -LiteralPath $jsonPath -Raw;
                    $jsonData = $jsonContent | ConvertFrom-Json;
                    
                    $area = $null;
                    if ($jsonData.PSObject.Properties.Name -contains "area") {
                        $area = $jsonData.area;
                    }
                    
                    if ($area -eq "Common") {
                        Write-Host "${indentStr}[COMMON] $($item.Name) - ${jsonData.name -if $jsonData.PSObject.Properties.Name -contains 'name' else 'No name'}";
                    }
                } catch {
                    Write-Host "${indentStr}[ERROR] $($item.Name) - Unable to parse JSON";
                }
            }
        }
    }
}

function Main() {
    Write-Host "=== CHARLIE CHAT BOARD FIXER ===";
    Write-Host "";
    
    $charsPath = "${CHARLIE_CHAT_ROOT}/lib/data/boards/Legends/Characters";
    
    Write-Host "1. Characters directory structure:";
    if (Test-Path -LiteralPath $charsPath) {
        Write-Host "✓ Characters directory exists: $charsPath";
        Write-Host "";
        Write-Host "Contents:";
        WalkDirectory -Path $charsPath -indent 2;
        Write-Host "";
        
        Write-Host "2. JSON files with area=\"Common\":";
        AnalyzeStructure -Path $charsPath -indent 2;
        Write-Host "";
    } else {
        Write-Host "✗ Characters directory does not exist at $charsPath";
        return;
    }
    
    Write-Host "=== ANALYSIS COMPLETE ===";
    Write-Host "";
    Write-Host "NEXT STEPS:";
    Write-Host "1. Update Characters board to use index.json pattern";
    Write-Host "2. Change area from 'Common' to 'Legends' in virtual_boards.txt";
    Write-Host "3. Fix dropdown menu order in Edit Board";
    Write-Host "4. Clean up Disney sub-boards";
    Write-Host "5. Repopulate Disney sub-boards with movie icons";
}

Main;
