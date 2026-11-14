# Graba los clips de marketing con el Movie Maker de Godot (scripts/ui/clip_director.gd) y los convierte a MP4.
# Salida: export/clips/<clip>_h.mp4 (1920x1080) y <clip>_v.mp4 (1080x1920), 30 fps, 10-16 s.
# MP4: H.264 -preset veryfast, CRF 20, AAC. Los verticales tienen que pesar < 50 MB y durar < 60 s: si pasan de 50 MB se
# reconvierte subiendo el CRF de a 2 hasta que entren. Despues de convertir se borra el AVI.
# Si falta Godot 4.4.1 o ffmpeg, llama a tools/setup.ps1 (ffmpeg via winget). -Ffmpeg fuerza una ruta.
#
# Uso:
#   powershell -File tools/record_clips.ps1                       # todos los clips, horizontal y vertical
#   powershell -File tools/record_clips.ps1 -Clips sobre_dorada,billete -Formats v
#   powershell -File tools/record_clips.ps1 -ConvertOnly          # solo convierte los AVI que ya existen
param(
  [string[]]$Clips = @("precio_empanada", "trillon_cafe", "tijera", "hiperinflacion", "sobre_dorada", "raspadita", "billete", "arbol"),
  [string[]]$Formats = @("h", "v"),
  [string]$Godot = "",
  [string]$Ffmpeg = "",
  [switch]$ConvertOnly
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_env.ps1")
Set-Location $RepoRoot
$Clips = Split-List $Clips
$Formats = Split-List $Formats

# Lo que falte (Godot 4.4.1, ffmpeg) se instala con setup.ps1
$need = @()
if ($Godot -eq "" -and -not $ConvertOnly -and -not (Find-Godot)) { $need += "godot" }
if (-not ($Ffmpeg -ne "" -and (Test-Path $Ffmpeg)) -and -not (Find-Ffmpeg)) { $need += "ffmpeg" }
if ($need.Count -gt 0) { Invoke-Setup $need }
if ($Godot -eq "") { $Godot = Find-Godot }
if (-not $ConvertOnly -and -not $Godot) { Write-Error "No encontre Godot $GodotVersion ni despues de tools\setup.ps1"; exit 1 }

$ff = if ($Ffmpeg -ne "" -and (Test-Path $Ffmpeg)) { (Resolve-Path $Ffmpeg).Path } else { Find-Ffmpeg }
if ($ff) { Write-Host "ffmpeg: $ff" }

# AVI -> MP4. Devuelve la ruta del mp4 (o $null si no hay ffmpeg).
function Convert-Clip($avi, $vertical) {
  if (-not $ff) { return $null }
  $mp4 = [IO.Path]::ChangeExtension($avi, "mp4")
  $limit = 50MB
  for ($crf = 20; $crf -le 30; $crf += 2) {
    $ErrorActionPreference = "Continue"
    & $ff -y -loglevel error -i $avi -c:v libx264 -preset veryfast -crf $crf -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart $mp4
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $mp4)) { Write-Error "ffmpeg fallo con $avi"; exit 5 }
    if (-not $vertical -or (Get-Item $mp4).Length -lt $limit) { break }
    Write-Host "  vertical de $([int]((Get-Item $mp4).Length/1MB)) MB con CRF $crf, subo el CRF"
  }
  Remove-Item $avi
  return $mp4
}

New-Item -ItemType Directory -Force "export\clips" | Out-Null
if ($ConvertOnly) {
  foreach ($a in Get-ChildItem "export\clips\*.avi") {
    Write-Host "Convirtiendo $($a.Name) ..."
    $m = Convert-Clip $a.FullName ($a.BaseName -like "*_v")
    if ($m) { Write-Host ("  -> {0} ({1:N1} MB)" -f $m, ((Get-Item $m).Length / 1MB)) } else { Write-Warning "No encontre ffmpeg: no se convirtio $($a.Name)" }
  }
  exit 0
}

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
    $m = Convert-Clip $avi ($f -eq "v")
    if ($m) { Write-Host ("  -> {0} ({1:N1} MB)" -f $m, ((Get-Item $m).Length / 1MB)) }
    else { Write-Host "  -> $avi (AVI MJPEG; no encontre ffmpeg, convertilo con: tools/record_clips.ps1 -ConvertOnly)" }
  }
}
Write-Host "Listo. Clips en export\clips\"
