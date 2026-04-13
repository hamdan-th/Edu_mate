$path = "lib\features\edu_bot\presentation\controllers\bot_controller.dart"
$fullPath = Resolve-Path $path

$content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)

# The broken line contains: .replaceAll(RegExp(r'[!?  ... ]'), ' ')
# We replace the entire cleanQuery block (lines 553-555) with a safe version.
# We search for the unique anchor "BUG FIX: Dart" comment block and replace the next replaceAll line.

$oldBlock = "    final cleanQuery = query`r`n        .replaceAll(RegExp(r'[!?" + [char]0x060c + [char]0x061f + [char]0x061b + ".,;:()\'`"\\[\\]{}]'), ' ')`r`n        .trim();"

# Safe replacement using double-quoted raw string
$newBlock = "    // Only strip actual punctuation; Arabic chars (U+0600-U+06FF) are preserved." + [char]13 + [char]10 +
            "    final cleanQuery = query" + [char]13 + [char]10 +
            "        .replaceAll(RegExp(r" + [char]34 + "[!?\u060c\u061f\u061b.,;:()'`"\[\]{}]" + [char]34 + "), ' ')" + [char]13 + [char]10 +
            "        .trim();"

Write-Host "Old block found: $($content.Contains('replaceAll(RegExp'))"

# Simpler approach: replace line 554 by line number
$lines = $content -split "`r`n"
Write-Host "Total lines: $($lines.Length)"
Write-Host "Line 554 content: $($lines[553])"

# Replace line 554 (index 553) with safe double-quoted raw string
$lines[553] = '        .replaceAll(RegExp(r"[!?\u060c\u061f\u061b.,;:()\u0027\u005b\u005d{}]"), ' + "' ')"

$newContent = $lines -join "`r`n"
[System.IO.File]::WriteAllText($fullPath, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "Done. New line 554: $($lines[553])"
