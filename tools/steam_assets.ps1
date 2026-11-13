# Genera TODAS las imagenes de la pagina de Steam en export/steam_assets/ :
#   - capsulas, hero y logo (tools/steam_assets.gd), iconos de logros (256x256, desbloqueado y bloqueado)
#   - 8 screenshots 1920x1080 (tour de capturas del juego) en export/steam_assets/screenshots/
# Que archivo va en que lugar de Steamworks: docs/STEAM_PAGE.md ("Imagenes de la pagina").
# Uso: powershell -File tools/steam_assets.ps1 [-SkipArt] [-SkipShots]
param([switch]$SkipArt, [switch]$SkipShots, [string]$Godot = "")
$ErrorActionPreference = "Continue"
Set-Location (Split-Path $PSScriptRoot -Parent)
if ($Godot -eq "") {
  $found = Get-Command godot -ErrorAction SilentlyContinue
  if ($found) { $Godot = $found.Source }
  else { $Godot = (Get-ChildItem "tools\godot_bin\Godot_v*_console.exe" | Select-Object -First 1).FullName }
}
$out = Join-Path (Get-Location) "export\steam_assets"
New-Item -ItemType Directory -Force "$out\screenshots", "$out\achievements" | Out-Null
& $Godot --headless --import | Out-Null

if (-not $SkipArt) {
  Write-Host "Capsulas, hero, logo e iconos de logros..."
  & $Godot --rendering-driver opengl3 res://tools/SteamAssets.tscn 2>&1 | Select-String "STEAM ASSETS OK|ERROR|SCRIPT"
}

if (-not $SkipShots) {
  # [ids de pasos del tour, [captura del tour -> nombre final]]
  $jobs = @(
    @{ only = "01";             map = @{ "00_tutorial" = "01_tutorial" } },
    @{ only = "02,02c,02d";     map = @{ "02_negocios_era3" = "02_era3_negocios"; "02d_inflacion_gana" = "03_indicador_inflacion"; "02c_decision" = "04_evento_decision" } },
    @{ only = "06,06b,06c,06d"; map = @{ "06_album" = "05_album"; "06d_sobre_dorada" = "06_sobre_abierto" } },
    @{ only = "06e,06f,06g";    map = @{ "06g_raspadita_pozo" = "07_raspadita_pozo" } },
    @{ only = "08";             map = @{ "08_hiperinflacion" = "08_hiperinflacion" } }
  )
  $tmp = Join-Path $out "screenshots\_tmp"
  foreach ($j in $jobs) {
    Remove-Item "$tmp\*" -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $env:TOUR_RES = "1920x1080"; $env:SHOT_DIR = $tmp; $env:TOUR_ONLY = $j.only; $env:SHOT_PNG = "1"
    Write-Host "Capturas: $($j.only)"
    & $Godot --rendering-driver opengl3 res://tests/ScreenshotTour.tscn 2>&1 | Select-String "TOUR OK|ERROR|SCRIPT"
    foreach ($k in $j.map.Keys) {
      $src = Join-Path $tmp "1920x1080_$k.png"
      if (Test-Path $src) { Copy-Item $src "$out\screenshots\$($j.map[$k]).png" -Force } else { Write-Warning "Falta la captura $k" }
    }
  }
  Remove-Item Env:TOUR_RES, Env:SHOT_DIR, Env:TOUR_ONLY, Env:SHOT_PNG -ErrorAction SilentlyContinue
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Get-ChildItem $out -Recurse -File | Where-Object { $_.FullName -notmatch "achievements" } | Select-Object @{n="archivo";e={$_.FullName.Substring($out.Length + 1)}}, @{n="KB";e={[int]($_.Length / 1KB)}}
Write-Host "Listo: $out"
