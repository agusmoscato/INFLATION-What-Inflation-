# Exporta INFLATION? What Inflation? a Windows, Windows Demo, Linux, Web y Web Demo en export/ (equivalente de export_all.sh).
# Despues de exportar cada .exe lo abre con --qa-screenshot (menu -> partida nueva -> negocios -> album -> timba, en es y en),
# y cada build web se prueba con Chrome headless (tools/web_qa.ps1: textos, raspadita y sobre con mouse, guardado al recargar),
# guarda capturas en user://qa/ y FALLA si algun Label visible es una clave de traduccion ("ui.", "biz.", ...).
#
# Si falta Godot 4.4.1, las templates, rcedit o el navegador del QA web, llama a tools/setup.ps1 y los instala.
# Cada build web queda tambien comprimido para itch.io: export/web/InflationWhatInflation_web.zip y
# export/web_demo/InflationWhatInflation_web_demo.zip (index.html en la raiz).
#
# Uso:
#   powershell -File tools/export_all.ps1                            # todo
#   powershell -File tools/export_all.ps1 -Targets windows,web_demo  # solo algunos
#   powershell -File tools/export_all.ps1 -NoQa                      # sin control de calidad
param(
  [string[]]$Targets = @("windows", "windows_demo", "linux", "web", "web_demo"),
  [switch]$NoQa,
  [string]$Godot = ""
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_env.ps1")
Set-Location $RepoRoot
$Name = "InflationWhatInflation"
$Targets = Split-List $Targets
$valid = @("windows", "windows_demo", "linux", "web", "web_demo")
foreach ($t in $Targets) { if ($valid -notcontains $t) { Write-Error "Destino desconocido: $t (validos: $($valid -join ', '))"; exit 1 } }

# Lo que falte se instala con setup.ps1
$need = @()
if ($Godot -eq "" -and -not (Find-Godot)) { $need += "godot" }
if (-not (Test-Templates)) { $need += "templates" }
if (($Targets -match "^windows") -and -not (Test-RceditConfigured)) { $need += "rcedit" }
if (-not $NoQa -and ($Targets -match "^web") -and -not (Find-Browser)) { $need += "browser" }
if ($need.Count -gt 0) { Invoke-Setup $need }
if ($Godot -eq "") { $Godot = Find-Godot }
if (-not $Godot) { Write-Error "No encontre Godot $GodotVersion ni despues de tools\setup.ps1"; exit 1 }
if (-not (Test-Templates)) { Write-Error "Faltan las export templates en $TemplatesDir ni despues de tools\setup.ps1"; exit 2 }
Write-Host "Godot: $Godot"
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
  }
  if ($t -eq "web" -or $t -eq "web_demo") {
    $dir = if ($t -eq "web") { "export\web" } else { "export\web_demo" }
    foreach ($f in "index.html", "index.js", "index.wasm", "index.pck") {
      if (-not (Test-Path "$dir\$f")) { Write-Error "Falta $dir\$f"; exit 3 }
    }
    Write-Host "Build web OK ($dir)."
    Qa-Web ($dir -replace "\\", "/") $(if ($t -eq "web") { 8061 } else { 8062 })
    # Zip para itch.io (index.html en la raiz, sin .import ni zips viejos)
    $zip = Join-Path (Resolve-Path $dir).Path "${Name}_$t.zip"
    if (Test-Path $zip) { Remove-Item $zip }
    $files = Get-ChildItem $dir -File | Where-Object { $_.Extension -notin ".import", ".zip" }
    Compress-Archive -Path $files.FullName -DestinationPath $zip
    Write-Host ("Zip: {0} ({1:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))
  }
}
Write-Host "Listo. Archivos en export\"
