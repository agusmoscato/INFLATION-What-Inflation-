# Graba los clips de marketing con el Movie Maker de Godot (scripts/ui/clip_director.gd).
# Salida: export/clips/<clip>_h.(mp4|avi) (1920x1080) y <clip>_v.(mp4|avi) (1080x1920), 30 fps, 10-16 s.
# Si hay ffmpeg en el PATH convierte a MP4 (H.264); si no, deja el AVI (MJPEG) y lo avisa.
#
# Uso:
#   powershell -File tools/record_clips.ps1                       # todos los clips, horizontal y vertical
#   powershell -File tools/record_clips.ps1 -Clips sobre_dorada -Formats v
param(
  [string[]]$Clips = @("precio_empanada", "trillon_cafe", "tijera", "hiperinflacion", "sobre_dorada", "raspadita_pozo", "quiniela"),
  [string[]]$Formats = @("h", "v"),
  [string]$Godot = ""
)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
if ($Godot -eq "") {
  $found = Get-Command godot -ErrorAction SilentlyContinue
  if ($found) { $Godot = $found.Source }
  else { $Godot = (Get-ChildItem "tools\godot_bin\Godot_v*_console.exe" | Select-Object -First 1).FullName }
}
$ff = Get-Command ffmpeg -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "export\clips" | Out-Null
& $Godot --headless --import | Out-Null
foreach ($c in $Clips) {
  foreach ($f in $Formats) {
    $size = if ($f -eq "v") { "1080x1920" } else { "1920x1080" }
    $avi = Join-Path (Resolve-Path "export\clips") "${c}_$f.avi"
    Write-Host "Grabando $c ($size) ..."
    # La ventana arranca chica (la pantalla puede ser mas baja que el clip) y el juego la agranda a --clip-size.
    # Si la PC esta cargada a veces se corta antes de tiempo: se reintenta hasta tener los >= 9 s completos (270 cuadros).
    $ok = $false
    for ($try = 1; $try -le 8 -and -not $ok; $try++) {
      $ErrorActionPreference = "Continue"
      $out = & $Godot --rendering-driver opengl3 --borderless --write-movie $avi --fixed-fps 30 --resolution 640x360 -- --record-clip $c --clip-size $size 2>&1 | Out-String
      $ErrorActionPreference = "Stop"
      $frames = 0
      if ($out -match "(\d+) frames at 30 FPS") { $frames = [int]$Matches[1] }
      if ($frames -ge 270 -and $out -notmatch "toma" -and (Test-Path $avi)) { $ok = $true } else { Write-Host "  intento ${try}: solo ${frames} cuadros, reintento"; $out | Set-Content (Join-Path $env:TEMP "clip_fail_${c}_${f}_${try}.log") }
    }
    if (-not $ok) { Write-Error "No se pudo grabar $avi completo"; exit 1 }
    if ($ff) {
      $mp4 = [IO.Path]::ChangeExtension($avi, "mp4")
      & ffmpeg -y -loglevel error -i $avi -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart $mp4
      Remove-Item $avi
      Write-Host "  -> $mp4"
    } else {
      Write-Host "  -> $avi (AVI MJPEG; instala ffmpeg para convertir a MP4)"
    }
  }
}
if (-not $ff) { Write-Warning "ffmpeg no esta instalado: los clips quedaron en AVI. Convertilos con: ffmpeg -i clip.avi -c:v libx264 -crf 18 -pix_fmt yuv420p clip.mp4" }
Write-Host "Listo. Clips en export\clips\"
