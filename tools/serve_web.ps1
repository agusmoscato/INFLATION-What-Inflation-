# Servidor estatico minimo para probar el build web localmente (sin Python ni Node).
# Uso: powershell -File tools/serve_web.ps1 -Dir export/web -Port 8060
param([string]$Dir = "export/web", [int]$Port = 8060)
$root = (Resolve-Path $Dir).Path
$types = @{ ".html"="text/html"; ".js"="text/javascript"; ".wasm"="application/wasm"; ".pck"="application/octet-stream"; ".png"="image/png"; ".json"="application/json" }
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Host "Sirviendo $root en http://localhost:$Port/ (Ctrl+C para cortar)"
while ($l.IsListening) {
  $ctx = $l.GetContext()
  $path = $ctx.Request.Url.LocalPath.TrimStart("/")
  if ($path -eq "") { $path = "index.html" }
  $file = Join-Path $root $path
  if (Test-Path $file -PathType Leaf) {
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $ctx.Response.ContentType = $(if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" })
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else { $ctx.Response.StatusCode = 404 }
  $ctx.Response.Close()
}
