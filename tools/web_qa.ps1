# QA del build web con Chrome headless (WebGL por software). Sirve el build, abre index.html?qa=web y chequea:
#   1. textos sin traducir (menu -> partida nueva -> negocios -> album -> timba, en es y en),
#   2. la raspadita con el mouse (arrastres reales por CDP) hasta que se revela,
#   3. la apertura de un sobre de figuritas rasgando con el mouse hasta mostrar las 5 figuritas,
#   4. que el guardado persista al recargar la pagina (IndexedDB): fase 2 carga la partida guardada.
# Capturas en export/qa_web/. Sale con codigo 0 si todo paso y 1 si algo fallo.
# Uso: powershell -File tools/web_qa.ps1 [-Dir export/web] [-Port 8061] [-TimeoutSec 400]
param(
  [string]$Dir = "export/web",
  [int]$Port = 8061,
  [int]$DebugPort = 9334,
  [int]$TimeoutSec = 400,
  [string]$Chrome = "",   # vacio: Chrome si esta, si no el Edge de Windows (tools/_env.ps1 Find-Browser)
  [string]$OutDir = "export/qa_web"
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_env.ps1")
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
if ($Chrome -eq "") { $Chrome = Find-Browser }
if (-not $Chrome -or -not (Test-Path $Chrome)) { Write-Error "No encontre Chrome ni Edge (corre tools/setup.ps1)"; exit 2 }
Write-Host "Navegador: $Chrome"

$serve = Start-Job -ScriptBlock { param($root, $d, $port) & powershell -NoProfile -File (Join-Path $root "tools\serve_web.ps1") -Dir (Join-Path $root $d) -Port $port } -ArgumentList (Get-Location).Path, $Dir, $Port
Start-Sleep 2
$profile = Join-Path $env:TEMP ("chrome_qa_" + [guid]::NewGuid().ToString("N"))
$p = Start-Process $Chrome -ArgumentList @("--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist",
  "--window-size=1280,720", "--remote-debugging-port=$DebugPort", "--user-data-dir=$profile", "about:blank") -PassThru
Start-Sleep 4
$results = @{ i18n = $null; scratch = $null; pack = $null; saved = $null; persist = $null }
$log = New-Object System.Collections.ArrayList
try {
  $targets = Invoke-RestMethod "http://localhost:$DebugPort/json"
  $wsUrl = ($targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1).webSocketDebuggerUrl
  $c = New-Object System.Net.WebSockets.ClientWebSocket
  $c.ConnectAsync([Uri]$wsUrl, [Threading.CancellationToken]::None).Wait()
  $script:nextId = 0
  function Send($method, $params) {
    $script:nextId++
    $msg = @{ id = $script:nextId; method = $method; params = $params } | ConvertTo-Json -Depth 6 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
    $c.SendAsync([ArraySegment[byte]]$bytes, "Text", $true, [Threading.CancellationToken]::None).Wait()
    return $script:nextId
  }
  $script:buf = New-Object byte[] 4194304
  $script:task = $null
  function Receive($ms) {
    $sb = New-Object Text.StringBuilder
    while ($true) {
      if ($null -eq $script:task) { $script:task = $c.ReceiveAsync([ArraySegment[byte]]$script:buf, [Threading.CancellationToken]::None) }
      if (-not $script:task.Wait($ms)) { return $null }
      $r = $script:task.Result
      $script:task = $null
      [void]$sb.Append([Text.Encoding]::UTF8.GetString($script:buf, 0, $r.Count))
      if ($r.EndOfMessage) { return $sb.ToString() }
    }
  }
  function Mouse($type, $x, $y, $buttons) {
    $pr = @{ type = $type; x = [double]$x; y = [double]$y; button = "left"; buttons = [int]$buttons; clickCount = 1 }
    [void](Send "Input.dispatchMouseEvent" $pr)
  }
  function Shot($name) {
    $id = Send "Page.captureScreenshot" @{ format = "png" }
    for ($i = 0; $i -lt 15; $i++) {
      $m = Receive 2000
      if ($m -and $m -match ('"id":' + $id + '[,}]')) {
        [IO.File]::WriteAllBytes((Join-Path $OutDir "$name.png"), [Convert]::FromBase64String((($m | ConvertFrom-Json).result.data)))
        return
      }
      if ($m) { Handle $m }
    }
  }
  function Drag-Scratch($x0, $y0, $x1, $y1) {
    Mouse "mouseMoved" $x0 $y0 0; Mouse "mousePressed" $x0 $y0 1
    $dir = 1
    $step = [Math]::Max(10, [int](($y1 - $y0) / 14))
    for ($y = $y0; $y -le $y1; $y += $step) {
      $xs = if ($dir -gt 0) { $x0..$x1 } else { $x1..$x0 }
      $k = 0
      foreach ($x in $xs) { if ($k % 16 -eq 0) { Mouse "mouseMoved" $x $y 1; Start-Sleep -Milliseconds 6 }; $k++ }
      $dir = -$dir
    }
    Mouse "mouseReleased" $x1 $y1 0
  }
  function Drag-Pack($x0, $y0, $x1, $y1) {
    Mouse "mouseMoved" $x0 $y0 0; Mouse "mousePressed" $x0 $y0 1
    for ($x = $x0; $x -le $x1; $x += 12) { Mouse "mouseMoved" $x $y0 1; Start-Sleep -Milliseconds 25 }
    Mouse "mouseMoved" $x1 $y0 1
    Mouse "mouseReleased" $x1 $y0 0
  }
  $script:phase = 1
  $script:reloadAt = $null
  function Handle($m) {
    if ($m -notmatch "consoleAPICalled|exceptionThrown") { return }
    $j = $m | ConvertFrom-Json
    if ($j.method -eq "Runtime.exceptionThrown") { [void]$log.Add("[exception] " + $j.params.exceptionDetails.text); return }
    $line = (($j.params.args | ForEach-Object { $_.value }) -join " ")
    if ($line -notmatch "^QA_") { if ($line -match "ERROR|SCRIPT") { [void]$log.Add("[" + $j.params.type + "] " + $line) }; return }
    Write-Host $line
    [void]$log.Add($line)
    switch -Regex ($line) {
      "^QA_I18N bad=(\d+)"     { $results.i18n = ([int]$Matches[1] -eq 0); if (-not $results.i18n) { Write-Host "  textos sin traducir: $line" } }
      "^QA_DRAG scratch ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)" { $g = $Matches; Shot "web_raspadita_antes"; Drag-Scratch ([int]$g[1]) ([int]$g[2]) ([int]$g[3]) ([int]$g[4]) }
      "^QA_SCRATCH done=(\w+)" { $results.scratch = ($Matches[1] -eq "true"); Shot "web_raspadita_despues" }
      "^QA_DRAG pack ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)" { $g = $Matches; Shot "web_sobre_antes"; Drag-Pack ([int]$g[1]) ([int]$g[2]) ([int]$g[3]) ([int]$g[4]) }
      "^QA_PACK state=(\d+)"   { $results.pack = ([int]$Matches[1] -eq 2); Shot "web_sobre_despues" }
      "^QA_SAVED"              { $results.saved = $line; $script:reloadAt = (Get-Date).AddSeconds(6) }
      "^QA_PERSIST loaded=(\w+) clicks=(\d+) packs=(\d+)" { $results.persist = ($Matches[1] -eq "true" -and [int]$Matches[2] -eq 4242 -and [int]$Matches[3] -ge 1); Shot "web_recargado" }
    }
  }
  [void](Send "Runtime.enable" @{})
  [void](Send "Page.enable" @{})
  [void](Send "Page.navigate" @{ url = "http://localhost:$Port/index.html?qa=web" })
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline -and $null -eq $results.persist) {
    $m = Receive 500
    if ($m) { Handle $m }
    if ($script:reloadAt -and (Get-Date) -gt $script:reloadAt) {
      $script:reloadAt = $null
      Write-Host "Recargando la pagina para probar el guardado..."
      [void](Send "Page.navigate" @{ url = "http://localhost:$Port/index.html?qa=web&phase=2" })
    }
  }
} finally {
  if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force }
  Stop-Job $serve -ErrorAction SilentlyContinue; Remove-Job $serve -Force -ErrorAction SilentlyContinue
  Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match "serve_web.ps1" -and $_.CommandLine -match "-Port $Port" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
$log | Where-Object { $_ -match "exception|ERROR|SCRIPT" } | ForEach-Object { Write-Host $_ }
function Mark($v) { if ($v -eq $true) { "OK" } elseif ($v -eq $false) { "FALLA" } else { "SIN RESPUESTA" } }
Write-Host ("Web QA [{0}]: textos={1}  raspadita={2}  sobre={3}  guardado_al_recargar={4}" -f $Dir, (Mark $results.i18n), (Mark $results.scratch), (Mark $results.pack), (Mark $results.persist))
if ($results.i18n -eq $true -and $results.scratch -eq $true -and $results.pack -eq $true -and $results.persist -eq $true) { Write-Host "WEB QA OK"; exit 0 }
Write-Host "WEB QA FALLA"; exit 1
