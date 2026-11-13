# Exporta INFLATION? What Inflation? a Windows, Windows Demo, Linux, Web y Web Demo en export/ (equivalente de export_all.sh).
# Despues de exportar cada .exe lo abre con --qa-screenshot (menu -> partida nueva -> negocios -> album -> timba, en es y en),
# y cada build web se prueba con Chrome headless (tools/web_qa.ps1: textos, raspadita y sobre con mouse, guardado al recargar),
# guarda capturas en user://qa/ y FALLA si algun Label visible es una clave de traduccion ("ui.", "biz.", ...).
#
# Uso:
#   powershell -File tools/export_all.ps1                     # todo
#   powershell -File tools/export_all.ps1 -Targets windows,web # solo algunos
#   powershell -File tools/export_all.ps1 -NoQa                # sin control de calidad
param(
  [string[]]$Targets = @("windows", "windows_demo", "linux", "web", "web_demo"),
  [switch]$NoQa,
  [string]$Godot = ""
)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$Name = "InflationWhatInflation"
if ($Godot -eq "") {
  $found = Get-Command godot -ErrorAction SilentlyContinue
  if ($found) { $Godot = $found.Source }
  else { $Godot = (Get-ChildItem "tools\godot_bin\Godot_v*_console.exe" | Select-Object -First 1).FullName }
}
if (-not $Godot) { Write-Error "No encontre Godot. Pasalo con -Godot ruta o ponelo en el PATH."; exit 1 }
Write-Host "Godot: $Godot"
$templates = Join-Path $env:APPDATA "Godot\export_templates\4.4.1.stable"
if (-not (Test-Path $templates)) {
  Write-Error "Faltan las export templates 4.4.1 en $templates. Instalalas desde el editor o con tools/export_all.sh --install-templates."
  exit 2
}
& $Godot --headless --import | Out-Null

function Export-One($preset, $out) {
  New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
  Write-Host "Exportando '$preset' -> $out"
  & $Godot --headless --export-release $preset $out
  if (-not (Test-Path $out) -or (Get-Item $out).Length -eq 0) { Write-Error "No se genero $out"; exit 3 }
}

function Qa-Exe($exe) {
  if ($NoQa) { Write-Host "QA: salteado (-NoQa)"; return }
  Write-Host "QA: abriendo $exe --qa-screenshot ..."
  $p = Start-Process -FilePath (Resolve-Path $exe).Path -ArgumentList "--", "--qa-screenshot" -PassThru -Wait
  if ($p.ExitCode -ne 0) {
    Write-Error "El control de calidad de $exe fallo (hay textos sin traducir o el juego no arranco). Revisa %APPDATA%\Godot\app_userdata\<proyecto>\qa\result.txt"
    exit 4
  }
  Write-Host "QA OK: $exe"
}


# QA del build web con Chrome headless (tools/web_qa.ps1): textos sin traducir, raspadita y sobre con el mouse, guardado al recargar.
function Qa-Web($dir, $port) {
  if ($NoQa) { Write-Host "QA web: salteado (-NoQa)"; return }
  Write-Host "QA web: $dir ..."
  & powershell -NoProfile -ExecutionPolicy Bypass -File "tools\web_qa.ps1" -Dir $dir -Port $port
  if ($LASTEXITCODE -ne 0) { Write-Error "El QA web de $dir fallo (ver capturas en export\qa_web\)"; exit 6 }
}

# QA de Linux: el binario solo se puede correr en Linux. En Windows se saltea (esta documentado en docs/DISENO_CAMBIOS.md).
function Qa-Linux($bin) {
  if ($NoQa) { return }
  Write-Host "QA Linux: salteado (el binario de Linux no se puede correr en Windows). Correr tools/export_all.sh en una maquina Linux."
}
foreach ($t in $Targets) {
  switch ($t) {
    "windows"      { Export-One "Windows Desktop" "export\windows\$Name.exe"; Qa-Exe "export\windows\$Name.exe" }
    "windows_demo" { Export-One "Windows Demo" "export\windows_demo\${Name}Demo.exe"; Qa-Exe "export\windows_demo\${Name}Demo.exe" }
    "linux"        { Export-One "Linux" "export\linux\$Name.x86_64"; Qa-Linux "export\linux\$Name.x86_64" }
    "web"          { Export-One "Web" "export\web\index.html" }
    "web_demo"     { Export-One "Web Demo" "export\web_demo\index.html" }
    default        { Write-Error "Destino desconocido: $t"; exit 1 }
  }
  if ($t -eq "web" -or $t -eq "web_demo") {
    $dir = if ($t -eq "web") { "export\web" } else { "export\web_demo" }
    foreach ($f in "index.html", "index.js", "index.wasm", "index.pck") {
      if (-not (Test-Path "$dir\$f")) { Write-Error "Falta $dir\$f"; exit 3 }
    }
    Write-Host "Build web OK ($dir)."
    Qa-Web ($dir -replace "\\", "/") $(if ($t -eq "web") { 8061 } else { 8062 })
  }
}
Write-Host "Listo. Archivos en export\"
