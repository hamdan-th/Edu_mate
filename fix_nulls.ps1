$p = Resolve-Path "lib\features\edu_bot\presentation\controllers\bot_controller.dart"
$c = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
$c = $c.Replace("suggestedFiles!.add(d);", "suggestedFiles.add(d);")
$c = $c.Replace('${suggestedFiles!.length}', '${suggestedFiles.length}')
[System.IO.File]::WriteAllText($p, $c, [System.Text.Encoding]::UTF8)
Write-Host "Replacements done"
