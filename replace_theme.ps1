$dir = "c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library"
$pattern = "LibraryTheme\.(primary|secondary|bg|surface|text|muted|border|danger|success|accent)\b(?!\()"
$replacement = 'LibraryTheme.$1(context)'

Get-ChildItem -Path $dir -Filter "*.dart" -Recurse | Where-Object { $_.Name -ne "library_theme.dart" } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match $pattern) {
        $newContent = [regex]::Replace($content, $pattern, $replacement)
        Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8
        Write-Host "Updated $($_.Name)"
    }
}
Write-Host "Done."
