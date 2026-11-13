# QA de la primera partida de un jugador nuevo: juega 5 minutos (x10) siguiendo la accion destacada, saca una captura cada 15 s
# de juego y arma la hoja de contacto docs/qa/primeros_5_min.jpg (todas las capturas juntas, con el tiempo de cada una).
# Uso: powershell -File tools/qa_newplayer.ps1
param([string]$Godot = "")
$ErrorActionPreference = "Continue"
Set-Location (Split-Path $PSScriptRoot -Parent)
if ($Godot -eq "") {
  $found = Get-Command godot -ErrorAction SilentlyContinue
  if ($found) { $Godot = $found.Source } else { $Godot = (Get-ChildItem "tools\godot_bin\Godot_v*_console.exe" | Select-Object -First 1).FullName }
}
$src = Join-Path $env:APPDATA "Godot\app_userdata\INFLATION- What Inflation-\qa\newplayer"
Remove-Item "$src\*" -Force -ErrorAction SilentlyContinue
& $Godot --rendering-driver opengl3 -- --qa-newplayer-shots 2>&1 | Select-String "QA newplayer|ERROR|SCRIPT"
$shots = Get-ChildItem "$src\t_*.png" | Sort-Object Name
if ($shots.Count -eq 0) { Write-Error "No se sacaron capturas"; exit 1 }
New-Item -ItemType Directory -Force "docs\qa" | Out-Null
Copy-Item "$src\log.csv" "docs\qa\primeros_5_min.csv" -Force
Add-Type -AssemblyName System.Drawing
$cols = 4; $cw = 480; $ch = 270; $rows = [math]::Ceiling($shots.Count / $cols)
$sheet = New-Object System.Drawing.Bitmap ($cols * $cw), ($rows * $ch)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::Black)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
$i = 0
foreach ($s in $shots) {
  $img = [System.Drawing.Image]::FromFile($s.FullName)
  $x = ($i % $cols) * $cw; $y = [math]::Floor($i / $cols) * $ch
  $g.DrawImage($img, $x, $y, $cw, $ch)
  $sec = [int]($s.BaseName.Substring(2, 3))
  $label = "{0}:{1:00}" -f [math]::Floor($sec / 60), ($sec % 60)
  if ($s.BaseName -like "*_cartel") { $label += " cartel" }
  $g.FillRectangle([System.Drawing.Brushes]::Black, $x, $y + $ch - 28, 150, 28)
  $g.DrawString($label, $font, [System.Drawing.Brushes]::Yellow, $x + 3, $y + $ch - 27)
  $img.Dispose(); $i++
}
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$p = New-Object System.Drawing.Imaging.EncoderParameters(1)
$p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 88L)
$sheet.Save((Join-Path (Get-Location) "docs\qa\primeros_5_min.jpg"), $enc, $p)
$g.Dispose(); $sheet.Dispose()
Write-Host "Hoja de contacto: docs\qa\primeros_5_min.jpg ($($shots.Count) capturas)"
$res = Join-Path $src "result.txt"
if (Test-Path $res) {
  $lines = Get-Content $res
  Write-Host ("QA jugador nuevo (carteles y notas): " + $lines[0])
  $lines | Select-Object -Skip 1 | Where-Object { $_ } | ForEach-Object { Write-Host "  $_" }
  if ($lines[0] -ne "PASS") { exit 1 }
}
