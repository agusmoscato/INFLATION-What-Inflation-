# QA del jugador nuevo (diseno v2): el bot del simulador (BotPolicy) juega 60 minutos con la interfaz real a velocidad x20
# (unos 3-4 minutos reales), saca capturas y arma dos hojas de contacto:
#   docs/qa/v2_0_a_10_min.jpg   una captura cada 30 s de juego (minutos 0 a 10)
#   docs/qa/v2_10_a_60_min.jpg  una captura cada 2,5 min de juego (minutos 10 a 60)
# Falla si hay textos sin traducir, si la pantalla se sale de la ventana, si la primera reforma no llega entre los
# minutos 4 y 6 o si pasan mas de 20 s sin nada comprable en la primera hora.
# Uso: powershell -File tools/qa_newplayer.ps1 [-Seconds 3600]
param([string]$Godot = "", [int]$Seconds = 3600)
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "_env.ps1")
Set-Location $RepoRoot
if ($Godot -eq "") { $Godot = Find-Godot }
if (-not $Godot) { Write-Error "No encontre Godot $GodotVersion (correr tools\setup.ps1)"; exit 2 }
$src = Join-Path $env:APPDATA "Godot\app_userdata\INFLATION- What Inflation-\qa\newplayer"
Remove-Item "$src\*" -Force -ErrorAction SilentlyContinue
& $Godot --rendering-driver opengl3 -- --qa-newplayer-shots --np-seconds $Seconds 2>&1 | Select-String "QA |ERROR|SCRIPT"
$code = $LASTEXITCODE
$all = Get-ChildItem "$src\t_*.png" | Sort-Object Name
if ($all.Count -eq 0) { Write-Error "No se sacaron capturas"; exit 1 }
New-Item -ItemType Directory -Force "docs\qa" | Out-Null
Copy-Item "$src\log.csv" "docs\qa\v2_jugador_nuevo.csv" -Force
Add-Type -AssemblyName System.Drawing
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$p = New-Object System.Drawing.Imaging.EncoderParameters(1)
$p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 85L)

function Sec-Of($f) { return [int]($f.BaseName.Substring(2, 4)) }

# Hoja de contacto: todas las capturas juntas en una imagen, con el tiempo de juego de cada una.
function Make-Sheet($shots, $outFile) {
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
    $sec = Sec-Of $s
    $label = "{0}:{1:00}" -f [math]::Floor($sec / 60), ($sec % 60)
    $g.FillRectangle([System.Drawing.Brushes]::Black, $x, $y + $ch - 28, 110, 28)
    $g.DrawString($label, $font, [System.Drawing.Brushes]::Yellow, $x + 3, $y + $ch - 27)
    $img.Dispose(); $i++
  }
  $sheet.Save((Join-Path (Get-Location) $outFile), $enc, $p)
  $g.Dispose(); $sheet.Dispose()
  Write-Host "Hoja de contacto: $outFile ($($shots.Count) capturas)"
}
$first = @($all | Where-Object { (Sec-Of $_) -le 600 })
$second = @($all | Where-Object { (Sec-Of $_) -ge 600 })
Make-Sheet $first "docs\qa\v2_0_a_10_min.jpg"
if ($second.Count -gt 0) { Make-Sheet $second "docs\qa\v2_10_a_60_min.jpg" }
$res = Join-Path $src "result.txt"
if (Test-Path $res) {
  $lines = Get-Content $res
  Write-Host ("QA jugador nuevo: " + $lines[0])
  $lines | Select-Object -Skip 1 | Where-Object { $_ } | ForEach-Object { Write-Host "  $_" }
  if ($lines[0] -ne "PASS") { exit 1 }
}
exit $code
