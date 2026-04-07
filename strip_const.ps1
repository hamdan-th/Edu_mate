$dir = "c:\Users\hamda\StudioProjects\Edu_mate\lib\screens\library"

Get-ChildItem -Path $dir -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    $orig_content = $content
    $content = [regex]::Replace($content, '\bconst\s+(?=[A-Z\[\{])', '')
    
    if ($content -cne $orig_content) {
        Set-Content -Path $_.FullName -Value $content -Encoding UTF8
        Write-Host "Updated $($_.Name)"
    }
}
Write-Host "Done stripping const."
