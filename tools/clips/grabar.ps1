# Grabacion cruda para los clips del estudio moscode.games (la edicion de marca la hace _estudio/tools/clip_tool.py).
# Basado en tools/record_clips.ps1 (que sigue igual para los clips viejos): mismo Movie Maker de Godot y mismos guiones
# de scripts/ui/clip_director.gd, pero:
#   - graba en ingles y en espanol (--clip-lang en|es: la interfaz del juego sale en ese idioma),
#   - sin los carteles de tiza del director (--clip-sin-carteles), porque el gancho va en la caja de marca,
#   - deja MP4 de alta calidad (CRF 16) en export/clips_crudos/<clip>_<idioma>.mp4, listos para editar.
#
# Uso (desde la raiz del repo o desde cualquier lado):
#   powershell -File tools/clips/grabar.ps1                                 # los 8 guiones, en y es, 1080x1920
#   powershell -File tools/clips/grabar.ps1 -Clips tijera,billete -Langs en
#   powershell -File tools/clips/grabar.ps1 -Size 1080x1080                 # cuadrado
#   powershell -File tools/clips/grabar.ps1 -ConCarteles                    # con los carteles de tiza del juego
#   powershell -File tools/clips/grabar.ps1 -Listar                         # muestra los guiones disponibles
# Guiones (clip_director.gd): precio_empanada 16 s, trillon_cafe 14, tijera 13, hiperinflacion 14, sobre_dorada 14,
# raspadita 14, billete 14, arbol 14. Para un momento nuevo hay que sumar un _clip_<nombre>() al director.
param(
  [string[]]$Clips = @("precio_empanada", "trillon_cafe", "tijera", "hiperinflacion", "sobre_dorada", "raspadita", "billete", "arbol"),
  [string[]]$Langs = @("en", "es"),
  [string]$Size = "1080x1920",
  [string]$Godot = "",
  [switch]$ConCarteles,
  [switch]$Listar
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\_env.ps1")
Set-Location $RepoRoot
$Clips = Split-List $Clips
$Langs = Split-List $Langs

if ($Listar) {
  Select-String -Path "scripts\ui\clip_director.gd" -Pattern '^# ---- (.+) ----' | ForEach-Object { $_.Matches[0].Groups[1].Value }
  Select-String -Path "scripts\ui\clip_director.gd" -Pattern '^\s+"(\w+)": _clip_' | ForEach-Object { "  " + $_.Matches[0].Groups[1].Value }
  exit 0
}

$need = @()
if ($Godot -eq "" -and -not (Find-Godot)) { $need += "godot" }
if (-not (Find-Ffmpeg)) { $need += "ffmpeg" }
if ($need.Count -gt 0) { Invoke-Setup $need }
if ($Godot -eq "") { $Godot = Find-Godot }
$ff = Find-Ffmpeg
if (-not $Godot -or -not $ff) { Write-Error "Falta Godot $GodotVersion o ffmpeg (corre tools\setup.ps1)"; exit 1 }

$outDir = Join-Path $RepoRoot "export\clips_crudos"
New-Item -ItemType Directory -Force $outDir | Out-Null
& $Godot --headless --import | Out-Null

$hechos = @()
foreach ($c in $Clips) {
  foreach ($lang in $Langs) {
    # el vertical (por defecto) queda <clip>_<idioma>.mp4; otros tamanos llevan el tamano en el nombre para no pisarlo
    $tag = if ($Size -eq "1080x1920") { "" } else { "_$Size" }
    $avi = Join-Path $outDir "${c}_$lang$tag.avi"
    $mp4 = Join-Path $outDir "${c}_$lang$tag.mp4"
    Write-Host "Grabando $c [$lang] ($Size) ..."
    $extra = @("--record-clip", $c, "--clip-size", $Size, "--clip-lang", $lang)
    if (-not $ConCarteles) { $extra += "--clip-sin-carteles" }
    # Igual que record_clips.ps1: ventana chica que el juego agranda; si la PC se traba se descarta la toma y se reintenta.
    $ok = $false
    for ($try = 1; $try -le 8 -and -not $ok; $try++) {
      $ErrorActionPreference = "Continue"
      $out = & $Godot --rendering-driver opengl3 --borderless --write-movie $avi --fixed-fps 30 --resolution 640x360 -- @extra 2>&1 | Out-String
      $ErrorActionPreference = "Stop"
      $frames = 0
      if ($out -match "(\d+) frames at 30 FPS") { $frames = [int]$Matches[1] }
      if ($frames -ge 270 -and $out -notmatch "toma" -and (Test-Path $avi)) { $ok = $true }
      else { Write-Host "  intento ${try}: solo ${frames} cuadros, reintento"; $out | Set-Content (Join-Path $env:TEMP "clip_fail_${c}_${lang}_${try}.log") }
    }
    if (-not $ok) { Write-Error "No se pudo grabar $c [$lang] completo"; exit 1 }
    # log de la toma (las sesiones largas imprimen "BEAT <segundo> <qué>" para elegir los tramos del montaje)
    $out | Set-Content -Encoding utf8 (Join-Path $outDir "${c}_$lang$tag.log")
    $ErrorActionPreference = "Continue"
    & $ff -y -loglevel error -i $avi -c:v libx264 -preset veryfast -crf 16 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart $mp4
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $mp4)) { Write-Error "ffmpeg fallo con $avi"; exit 5 }
    Remove-Item $avi
    Write-Host ("  -> {0} ({1:N1} MB)" -f $mp4, ((Get-Item $mp4).Length / 1MB))
    $hechos += $mp4
  }
}
Write-Host "Listo: $($hechos.Count) grabaciones en export\clips_crudos\ (editar con _estudio/tools/clip_tool.py)"
