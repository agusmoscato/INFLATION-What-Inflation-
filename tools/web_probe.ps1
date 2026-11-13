# Abre el build web en Chrome headless (WebGL por software), espera, imprime los mensajes de la consola y guarda una captura.
# Uso: powershell -File tools/web_probe.ps1 -Url http://localhost:8060/ -Out shot.png -Wait 45
param(
  [string]$Url = "http://localhost:8060/",
  [string]$Out = "web_probe.png",
  [int]$Wait = 45,
  [string]$Chrome = "",   # vacio: Chrome si esta, si no el Edge de Windows
  [int]$Port = 9333,
  [string]$Click = "",
  [int]$Wait2 = 35,
  [string]$Eval = "",
  [string]$Width = "1280",
  [string]$Height = "720"
)
. (Join-Path $PSScriptRoot "_env.ps1")
if ($Chrome -eq "") { $Chrome = Find-Browser }
if (-not $Chrome) { Write-Error "No encontre Chrome ni Edge (corre tools/setup.ps1)"; exit 2 }
$profile = Join-Path $env:TEMP ("chrome_probe_" + [guid]::NewGuid().ToString("N"))
$p = Start-Process $Chrome -ArgumentList @("--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist",
  "--window-size=$Width,$Height", "--remote-debugging-port=$Port", "--user-data-dir=$profile", "about:blank") -PassThru
Start-Sleep 4
try {
  $targets = Invoke-RestMethod "http://localhost:$Port/json"
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
  # Devuelve el proximo mensaje completo o $null si no llega en $ms (sin cancelar el socket).
  function Receive($ms) {
    $sb = New-Object Text.StringBuilder
    while ($true) {
      if ($null -eq $script:task) {
        $script:task = $c.ReceiveAsync([ArraySegment[byte]]$script:buf, [Threading.CancellationToken]::None)
      }
      if (-not $script:task.Wait($ms)) { return $null }
      $r = $script:task.Result
      $script:task = $null
      [void]$sb.Append([Text.Encoding]::UTF8.GetString($script:buf, 0, $r.Count))
      if ($r.EndOfMessage) { return $sb.ToString() }
    }
  }
  [void](Send "Runtime.enable" @{})
  [void](Send "Log.enable" @{})
  [void](Send "Page.enable" @{})
  [void](Send "Page.navigate" @{ url = $Url })
  $deadline = (Get-Date).AddSeconds($Wait)
  while ((Get-Date) -lt $deadline) {
    $m = Receive 1000
    if ($m -and ($m -match "consoleAPICalled|entryAdded|exceptionThrown")) {
      $j = $m | ConvertFrom-Json
      if ($j.method -eq "Runtime.consoleAPICalled") { Write-Host ("[console." + $j.params.type + "] " + (($j.params.args | ForEach-Object { $_.value }) -join " ")) }
      elseif ($j.method -eq "Log.entryAdded") { Write-Host ("[log." + $j.params.entry.level + "] " + $j.params.entry.text) }
      elseif ($j.method -eq "Runtime.exceptionThrown") { Write-Host ("[exception] " + $j.params.exceptionDetails.text + " " + $j.params.exceptionDetails.exception.description) }
    }
  }
  if ($Click -ne "") {
    $xy = $Click.Split(",")
    foreach ($ty in @("mouseMoved", "mousePressed", "mouseReleased")) {
      [void](Send "Input.dispatchMouseEvent" @{ type = $ty; x = [double]$xy[0]; y = [double]$xy[1]; button = "left"; clickCount = 1 })
      Start-Sleep -Milliseconds 120
    }
    $deadline2 = (Get-Date).AddSeconds($Wait2)
    while ((Get-Date) -lt $deadline2) { [void](Receive 1000) }
  }
  if ($Eval -ne "") {
    $eid = Send "Runtime.evaluate" @{ expression = $Eval; awaitPromise = $true; returnByValue = $true }
    for ($i = 0; $i -lt 30; $i++) {
      $m = Receive 2000
      if ($m -and $m -match ('"id":' + $eid + '[,}]')) { Write-Host ("[eval] " + (($m | ConvertFrom-Json).result.result.value)); break }
    }
  }
  $id = Send "Page.captureScreenshot" @{ format = "png" }
  for ($i = 0; $i -lt 30; $i++) {
    $m = Receive 2000
    if ($m -and $m -match '"id":' + $id) {
      $j = $m | ConvertFrom-Json
      [IO.File]::WriteAllBytes($Out, [Convert]::FromBase64String($j.result.data))
      Write-Host "Captura guardada en $Out"
      break
    }
  }
} finally {
  if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force }
}
