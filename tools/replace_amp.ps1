# Replace all occurrences of ' & ' with ' and ' in text documentation/data files.
$extensions = @('.txt','.md','.yaml','.yml','.json','.dart')
$excluded = @('\build\','\.dart_tool\','\.git\')

$files = Get-ChildItem -Path '.' -Recurse -File | Where-Object {
    $file = $_
    ($file.Extension -in $extensions) -and
    ($excluded | ForEach-Object { $file.FullName.Contains($_) } | Where-Object { $_ } | Measure-Object).Count -eq 0
}

$count = 0
foreach ($file in $files) {
    $path = $file.FullName
    $text = [System.IO.File]::ReadAllText($path)
    if ($text.Contains(' & ')) {
        $text = $text -replace ' & ', ' and '
        [System.IO.File]::WriteAllText($path, $text)
        $count++
        Write-Host $path
    }
}

Write-Host "Updated $count files"
