# Genera docs/steam_achievements.csv (formato para cargar en Steamworks) desde data/achievements.json + i18n/*.txt.
# Columnas: API name, nombre es, descripcion es, nombre en, descripcion en, icono desbloqueado, icono bloqueado, oculto.
Set-Location (Split-Path $PSScriptRoot -Parent)
$tr = @{}
foreach ($f in Get-ChildItem i18n\*.txt) {
  foreach ($line in Get-Content $f.FullName -Encoding UTF8) {
    if ($line -match '^"(ach\.[^"]+)","((?:[^"]|"")*)","((?:[^"]|"")*)"') { $tr[$Matches[1]] = @($Matches[2], $Matches[3]) }
  }
}
$ach = Get-Content data\achievements.json -Raw -Encoding UTF8 | ConvertFrom-Json
$hidden = @("album_60", "lost_all", "win")
$rows = @()
$rows += "api_name,nombre_es,descripcion_es,name_en,description_en,icono,icono_bloqueado,oculto"
foreach ($a in $ach) {
  $id = $a.id
  $n = $tr["ach.$id"]; $d = $tr["ach.$id.d"]
  if (-not $n -or -not $d) { Write-Warning "Sin traduccion para $id"; continue }
  $api = $id      # el API name de Steamworks es el id del juego, sin mapeo
  $h = if ($hidden -contains $id) { 1 } else { 0 }
  $rows += ('"{0}","{1}","{2}","{3}","{4}","achievements/{5}.png","achievements/{5}_locked.png",{6}' -f $api, $n[0], $d[0], $n[1], $d[1], $id, $h)
}
$rows | Set-Content docs\steam_achievements.csv -Encoding UTF8
Write-Host "docs/steam_achievements.csv: $($rows.Count - 1) logros"
