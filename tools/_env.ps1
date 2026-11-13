# Funciones compartidas por setup.ps1, export_all.ps1, record_clips.ps1 y web_qa.ps1 (se cargan con ". tools\_env.ps1").
# Solo buscan herramientas; no instalan nada (eso lo hace tools/setup.ps1).

$GodotVersion = "4.4.1"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$GodotBinDir = Join-Path $RepoRoot "tools\godot_bin"
$TemplatesDir = Join-Path $env:APPDATA "Godot\export_templates\$GodotVersion.stable"
# Templates que exige export_presets.cfg (Windows, Linux y Web sin threads), release y debug.
$TemplateFiles = @(
  "windows_release_x86_64.exe", "windows_debug_x86_64.exe",
  "windows_release_x86_64_console.exe", "windows_debug_x86_64_console.exe",
  "linux_release.x86_64", "linux_debug.x86_64",
  "web_nothreads_release.zip", "web_nothreads_debug.zip"
)

# Relee el PATH de Windows (lo que instala winget no aparece en la sesion actual hasta reiniciar la terminal).
function Update-SessionPath {
  $m = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $u = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = (@($m, $u, $env:Path) | Where-Object { $_ }) -join ";"
}

# Godot de consola 4.4.1: primero tools\godot_bin, despues el PATH (solo si es la 4.4.1).
function Find-Godot {
  $c = Join-Path $GodotBinDir "Godot_v$GodotVersion-stable_win64_console.exe"
  if (Test-Path $c) { return $c }
  $g = Get-Command godot -ErrorAction SilentlyContinue
  if ($g) {
    $v = (& $g.Source --version 2>$null | Out-String).Trim()
    if ($v -like "$GodotVersion.stable*") { return $g.Source }
  }
  return $null
}

function Find-GodotEditor {
  $e = Join-Path $GodotBinDir "Godot_v$GodotVersion-stable_win64.exe"
  if (Test-Path $e) { return $e }
  return $null
}

function Test-Templates {
  foreach ($f in $TemplateFiles) { if (-not (Test-Path (Join-Path $TemplatesDir $f))) { return $false } }
  return $true
}

function Find-Rcedit {
  foreach ($n in "rcedit-x64.exe", "rcedit.exe") {
    $p = Join-Path $RepoRoot "tools\$n"
    if (Test-Path $p) { return $p }
  }
  return $null
}

# Archivo de configuracion del editor de Godot 4.4 (ahi va export/windows/rcedit).
$EditorSettings = Join-Path $env:APPDATA "Godot\editor_settings-4.4.tres"
function Test-RceditConfigured {
  $r = Find-Rcedit
  if (-not $r -or -not (Test-Path $EditorSettings)) { return $false }
  $want = 'export/windows/rcedit = "' + ($r -replace "\\", "/") + '"'
  return [bool](Select-String -Path $EditorSettings -SimpleMatch $want -Quiet)
}

# ffmpeg: variable FFMPEG, PATH (incluido el de Windows releido), WinGet\Links, paquetes de winget, Chocolatey, Scoop.
function Find-Ffmpeg {
  if ($env:FFMPEG -and (Test-Path $env:FFMPEG)) { return $env:FFMPEG }
  $c = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  $p = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  foreach ($d in ($p -split ";")) { if ($d -and (Test-Path (Join-Path $d "ffmpeg.exe"))) { return (Join-Path $d "ffmpeg.exe") } }
  foreach ($x in @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\ffmpeg.exe", "$env:ProgramData\chocolatey\bin\ffmpeg.exe",
                   "$env:USERPROFILE\scoop\shims\ffmpeg.exe")) { if (Test-Path $x) { return $x } }
  foreach ($root in @("$env:LOCALAPPDATA\Microsoft\WinGet\Packages", "$env:ProgramFiles\WinGet\Packages")) {
    $pk = Get-ChildItem "$root\Gyan.FFmpeg*" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pk) { return $pk.FullName }
  }
  return $null
}

# Chrome si esta instalado; si no, el Edge que trae Windows (los dos sirven para el QA web headless).
function Find-Browser {
  $cands = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
  )
  foreach ($c in $cands) { if ($c -and (Test-Path $c)) { return $c } }
  foreach ($k in "chrome.exe", "msedge.exe") {
    $r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$k" -ErrorAction SilentlyContinue
    if ($r -and $r.'(default)' -and (Test-Path $r.'(default)')) { return $r.'(default)' }
  }
  return $null
}

# Separa "-Targets windows,web_demo" (powershell -File pasa todo como un solo texto) en una lista.
function Split-List([string[]]$items) {
  return @($items | ForEach-Object { $_ -split "[,; ]+" } | Where-Object { $_ -ne "" })
}

# Llama a setup.ps1 (instala lo que falte). Sale si falla.
function Invoke-Setup([string[]]$Only) {
  Write-Host "Falta algo para trabajar ($($Only -join ', ')): corro tools\setup.ps1 ..."
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot "tools\setup.ps1") -Only ($Only -join ",")
  if ($LASTEXITCODE -ne 0) { Write-Error "tools\setup.ps1 fallo (codigo $LASTEXITCODE)"; exit 10 }
  Update-SessionPath
}
