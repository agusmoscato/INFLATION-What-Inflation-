# QA del jugador nuevo (diseno v2): un jugador de prueba del simulador (BotPolicy: activo, pasivo o distraido) juega con
# la interfaz real a velocidad x20, saca capturas y arma hojas de contacto:
#   docs/qa/v2_0_a_10_min_<perfil>.jpg   una captura cada 30 s de juego (minutos 0 a 10)
#   docs/qa/v2_10_a_60_min_<perfil>.jpg  una captura cada 2,5 min de juego (minutos 10 a 60, si se juega tanto)
# Falla si hay textos sin traducir, si la pantalla se sale de la ventana, si pasan mas de 20 s sin poder comprar ni
# reformar, si una reforma da menos de 5 de Credibilidad, si la vuelta 2 es mas lenta que la 1 o (jugador activo) si la
# primera reforma no llega entre los minutos 4 y 6.
# Uso: powershell -File tools/qa_newplayer.ps1 [-Seconds 600] [-Profile pasivo]
param([string]$Godot = "", [int]$Seconds = 600, [string]$Profile = "pasivo")
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "_env.ps1")
Set-Location $RepoRoot
if ($Godot -eq "") { $Godot = Find-Godot }
if (-not $Godot) { Write-Error "No encontre Godot $GodotVersion (correr tools\setup.ps1)"; exit 2 }
$src = Join-Path $env:APPDATA "Godot\app_userdata\INFLATION- What Inflation-\qa\newplayer"
Remove-Item "$src\*" -Force -ErrorAction SilentlyContinue
& $Godot --rendering-driver opengl3 -- --qa-newplayer-shots --np-seconds $Seconds --np-profile $Profile 2>&1 | Select-String "QA |ERROR|SCRIPT"
$code = $LASTEXITCODE
$all = Get-ChildItem "$src\t_*.png" | Sort-Object Name
if ($all.Count -eq 0) { Write-Error "No se sacaron capturas"; exit 1 }
New-Item -ItemType Directory -Force "docs\qa" | Out-Null
Copy-Item "$src\log.csv" "docs\qa\v2_jugador_nuevo_$Profile.csv" -Force
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
Make-Sheet $first "docs\qa\v2_0_a_10_min_$Profile.jpg"
if ($second.Count -gt 1) { Make-Sheet $second "docs\qa\v2_10_a_60_min_$Profile.jpg" }
$res = Join-Path $src "result.txt"
if (Test-Path $res) {
  $lines = Get-Content $res
  Write-Host ("QA jugador nuevo: " + $lines[0])
  $lines | Select-Object -Skip 1 | Where-Object { $_ } | ForEach-Object { Write-Host "  $_" }
  if ($lines[0] -ne "PASS") { exit 1 }
}
exit $code
