# Prepara una PC nueva para exportar, testear y grabar clips de INFLATION? What Inflation?. No pide nada.
# Se puede correr las veces que quieras: lo que ya esta instalado se saltea.
#
#   - Godot 4.4.1-stable (editor + consola)       -> tools\godot_bin\
#   - Export templates 4.4.1 (Windows, Web, Linux) -> %APPDATA%\Godot\export_templates\4.4.1.stable\
#   - rcedit (electron/rcedit)                     -> tools\rcedit-x64.exe, configurado en el editor de Godot 4.4
#   - ffmpeg (si no esta, winget install Gyan.FFmpeg)
#   - Chrome o Edge para el QA web (si no hay Chrome se usa el Edge de Windows)
#
# Uso:
#   powershell -File tools/setup.ps1                     # todo
#   powershell -File tools/setup.ps1 -Only godot,ffmpeg  # solo algunas (godot, templates, rcedit, ffmpeg, browser)
param(
  [string[]]$Only = @("godot", "templates", "rcedit", "ffmpeg", "browser")
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # Invoke-WebRequest es lentisimo con la barra de progreso en PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
. (Join-Path $PSScriptRoot "_env.ps1")
Set-Location $RepoRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Only = Split-List $Only
$Base = "https://github.com/godotengine/godot/releases/download/$GodotVersion-stable"
$failed = @()

function Get-File($url, $dest) {
  Write-Host "  bajando $url"
  $tmp = "$dest.part"
  if (Test-Path $tmp) { Remove-Item $tmp -Force }
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curl) {
    & $curl.Source -L --fail --retry 3 --silent --show-error -o $tmp $url
    if ($LASTEXITCODE -ne 0) { throw "curl fallo ($LASTEXITCODE) bajando $url" }
  } else {
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
  }
  Move-Item $tmp $dest -Force
}

function Step($name, [scriptblock]$body) {
  if ($Only -notcontains $name) { return }
  Write-Host "== $name"
  try { & $body } catch { Write-Warning "$name fallo: $($_.Exception.Message)"; $script:failed += $name }
}

# --- Godot ---
Step "godot" {
  if ((Test-Path (Join-Path $GodotBinDir "Godot_v$GodotVersion-stable_win64_console.exe")) -and (Find-GodotEditor)) {
    Write-Host "  ya esta en $GodotBinDir"; return
  }
  New-Item -ItemType Directory -Force $GodotBinDir | Out-Null
  $zip = Join-Path $GodotBinDir "godot.zip"
  Get-File "$Base/Godot_v$GodotVersion-stable_win64.exe.zip" $zip
  $z = [IO.Compression.ZipFile]::OpenRead($zip)
  try {
    foreach ($e in $z.Entries) {
      if ($e.Name -like "Godot_v*.exe") { [IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $GodotBinDir $e.Name), $true) }
    }
  } finally { $z.Dispose() }
  Remove-Item $zip
  # Modo autocontenido: el editor guarda su configuracion en %APPDATA%\Godot (no en tools\godot_bin), asi que no se crea _sc_.
  $v = (& (Find-Godot) --version | Out-String).Trim()
  Write-Host "  instalado: $v"
}

# --- Export templates (solo Windows, Web y Linux) ---
Step "templates" {
  if (Test-Templates) { Write-Host "  ya estan en $TemplatesDir"; return }
  New-Item -ItemType Directory -Force $TemplatesDir | Out-Null
  $tpz = Join-Path $env:TEMP "Godot_v$GodotVersion-stable_export_templates.tpz"
  if (-not (Test-Path $tpz)) { Get-File "$Base/Godot_v$GodotVersion-stable_export_templates.tpz" $tpz }
  try {
    $z = [IO.Compression.ZipFile]::OpenRead($tpz)
    try {
      $want = @($TemplateFiles) + "version.txt"
      foreach ($e in $z.Entries) {
        if ($want -contains $e.Name) {
          Write-Host "  extrayendo $($e.Name)"
          [IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $TemplatesDir $e.Name), $true)
        }
      }
    } finally { $z.Dispose() }
  } finally { Remove-Item $tpz -Force -ErrorAction SilentlyContinue }
  if (-not (Test-Templates)) { throw "faltan templates despues de extraer" }
}

# --- rcedit ---
Step "rcedit" {
  $r = Find-Rcedit
  if (-not $r) {
    $r = Join-Path $RepoRoot "tools\rcedit-x64.exe"
    Get-File "https://github.com/electron/rcedit/releases/latest/download/rcedit-x64.exe" $r
  } else { Write-Host "  ya esta: $r" }
  if (Test-RceditConfigured) { Write-Host "  ya configurado en $EditorSettings"; return }
  $line = 'export/windows/rcedit = "' + ($r -replace "\\", "/") + '"'
  if (Test-Path $EditorSettings) {
    $txt = [IO.File]::ReadAllText($EditorSettings)
    if ($txt -match '(?m)^export/windows/rcedit = .*$') { $txt = $txt -replace '(?m)^export/windows/rcedit = .*$', $line }
    else { $txt = $txt.TrimEnd() + "`n$line`n" }
  } else {
    New-Item -ItemType Directory -Force (Split-Path $EditorSettings) | Out-Null
    $txt = "[gd_resource type=`"EditorSettings`" format=3]`n`n[resource]`n$line`n"
  }
  [IO.File]::WriteAllText($EditorSettings, $txt, (New-Object Text.UTF8Encoding $false))
  Write-Host "  configurado en $EditorSettings"
}

# --- ffmpeg ---
Step "ffmpeg" {
  $f = Find-Ffmpeg
  if ($f) { Write-Host "  ya esta: $f"; return }
  $wg = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $wg) { throw "no hay ffmpeg ni winget (instala 'App Installer' desde la Microsoft Store)" }
  & $wg.Source install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements --disable-interactivity
  Update-SessionPath
  $f = Find-Ffmpeg
  if (-not $f) { throw "winget termino pero no encuentro ffmpeg.exe" }
  Write-Host "  instalado: $f"
}

# --- Navegador para el QA web ---
Step "browser" {
  $b = Find-Browser
  if ($b) { Write-Host "  $b"; return }
  $wg = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $wg) { throw "no hay Chrome ni Edge ni winget" }
  & $wg.Source install --id Microsoft.Edge -e --accept-source-agreements --accept-package-agreements --disable-interactivity
  if (-not (Find-Browser)) { throw "no encuentro Chrome ni Edge" }
}

# --- Resumen ---
$ok = [string][char]0x2714; $no = [string][char]0x2718
$god = Find-Godot
$rows = @(
  @("Godot $GodotVersion (consola)", $god),
  @("Godot $GodotVersion (editor)", (Find-GodotEditor)),
  @("Export templates", $(if (Test-Templates) { $TemplatesDir } else { $null })),
  @("rcedit", $(if (Test-RceditConfigured) { Find-Rcedit } else { $null })),
  @("ffmpeg", (Find-Ffmpeg)),
  @("Navegador (QA web)", (Find-Browser))
)
Write-Host ""
Write-Host "Resumen:"
$missing = 0
foreach ($r in $rows) {
  if ($r[1]) { Write-Host ("  {0} {1,-28} {2}" -f $ok, $r[0], $r[1]) -ForegroundColor Green }
  else { Write-Host ("  {0} {1,-28} (falta)" -f $no, $r[0]) -ForegroundColor Red; $missing++ }
}
if ($failed.Count -gt 0) { Write-Host "Fallaron: $($failed -join ', ')" -ForegroundColor Red; exit 1 }
exit 0
