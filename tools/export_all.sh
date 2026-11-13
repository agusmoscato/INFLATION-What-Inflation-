#!/usr/bin/env bash
# Exporta INFLATION? What Inflation? a Windows, Linux y Web en export/.
#
# Uso:
#   tools/export_all.sh                      # exporta los tres (requiere export templates instaladas)
#   tools/export_all.sh --install-templates  # baja e instala las templates de Godot (~1 GB) y exporta
#   tools/export_all.sh --check              # solo verifica que todo esté listo
#   tools/export_all.sh windows web          # exporta solo algunos (windows, windows_demo, linux, web, web_demo)
#   tools/export_all.sh --no-qa              # sin el control de calidad (.exe, Linux y web)
#
# Variables opcionales:
#   GODOT=/ruta/a/godot   (por defecto: godot del PATH o tools/godot_bin/Godot_v*_console.exe)
#   GODOT_VERSION=4.4.1   (version de las export templates)
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${GODOT_VERSION:-4.4.1}"
NAME="InflationWhatInflation"

# --- localizar Godot ---
if [[ -z "${GODOT:-}" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT="godot"
  else
    GODOT="$(ls tools/godot_bin/Godot_v*_console.exe tools/godot_bin/Godot_v*linux* 2>/dev/null | head -1 || true)"
  fi
fi
if [[ -z "${GODOT:-}" ]]; then
  echo "ERROR: no encontré Godot. Definí GODOT=/ruta/a/godot o ponelo en el PATH." >&2
  exit 1
fi
echo "Godot: $GODOT ($("$GODOT" --version 2>/dev/null | head -1))"

# --- carpeta de export templates segun el sistema ---
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) TEMPLATES_DIR="${APPDATA}/Godot/export_templates/${VERSION}.stable" ;;
  Darwin) TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/${VERSION}.stable" ;;
  *) TEMPLATES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSION}.stable" ;;
esac

install_templates() {
  local url="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_export_templates.tpz"
  local tmp
  tmp="$(mktemp -d)"
  echo "Bajando templates de $url ..."
  curl -L --fail -o "$tmp/templates.tpz" "$url"
  (cd "$tmp" && unzip -q templates.tpz)
  mkdir -p "$TEMPLATES_DIR"
  cp -r "$tmp"/templates/* "$TEMPLATES_DIR"/
  rm -rf "$tmp"
  echo "Templates instaladas en $TEMPLATES_DIR"
}

ARGS=()
CHECK_ONLY=0
NO_QA=0
for a in "$@"; do
  case "$a" in
    --install-templates) install_templates ;;
    --check) CHECK_ONLY=1 ;;
    --no-qa) NO_QA=1 ;;
    *) ARGS+=("$a") ;;
  esac
done

if [[ ! -d "$TEMPLATES_DIR" ]]; then
  echo "ERROR: faltan las export templates de Godot ${VERSION} en:" >&2
  echo "       $TEMPLATES_DIR" >&2
  echo "       Instalalas desde el editor (Editor > Manage Export Templates) o corré:" >&2
  echo "       tools/export_all.sh --install-templates" >&2
  exit 2
fi
echo "Export templates: OK ($TEMPLATES_DIR)"
if [[ $CHECK_ONLY -eq 1 ]]; then
  echo "Todo listo para exportar."
  exit 0
fi

TARGETS=("${ARGS[@]:-windows windows_demo linux web web_demo}")
[[ ${#ARGS[@]} -eq 0 ]] && TARGETS=(windows windows_demo linux web web_demo)

echo "Importando recursos..."
"$GODOT" --headless --import >/dev/null 2>&1 || true

export_one() {
  local preset="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  echo "Exportando '$preset' -> $out"
  "$GODOT" --headless --export-release "$preset" "$out"
  [[ -s "$out" ]] || { echo "ERROR: no se generó $out" >&2; exit 3; }
}

# Control de calidad: abre el exe con --qa-screenshot (menú -> partida nueva -> negocios -> álbum -> timba, en es y en),
# guarda capturas en user://qa/ y falla si algún Label visible es una clave de traducción ("ui.", "biz.", ...).
# Solo se puede correr el exe de la plataforma donde estamos (Windows acá).
qa_windows_exe() {
  local exe="$1"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) echo "QA: salteado (no se puede correr un .exe en este sistema)"; return 0 ;;
  esac
  [[ $NO_QA -eq 1 ]] && { echo "QA: salteado (--no-qa)"; return 0; }
  echo "QA: abriendo $exe --qa-screenshot ..."
  local winpath
  winpath="$(cygpath -w "$(realpath "$exe")")"
  if ! powershell.exe -NoProfile -Command "\$p = Start-Process -FilePath '$winpath' -ArgumentList '--','--qa-screenshot' -PassThru -Wait; exit \$p.ExitCode"; then
    echo "ERROR: el control de calidad de $exe falló (hay textos sin traducir o el juego no arrancó)." >&2
    echo "       Revisá user://qa/result.txt (en %APPDATA%/Godot/app_userdata/<proyecto>/qa/)." >&2
    exit 4
  fi
  echo "QA OK: $exe (capturas en %APPDATA%/Godot/app_userdata/<proyecto>/qa/)"
}


# QA de Linux: corre el binario con --qa-screenshot (mismo control que el .exe). Solo se puede en un Linux; en Windows se saltea.
qa_linux_bin() {
  local bin="$1"
  [[ $NO_QA -eq 1 ]] && { echo "QA Linux: salteado (--no-qa)"; return 0; }
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "QA Linux: salteado (el binario de Linux no se puede correr en $(uname -s)). Correr este script en una maquina Linux."
    return 0
  fi
  chmod +x "$bin"
  echo "QA: abriendo $bin --qa-screenshot ..."
  local runner=()
  if [[ -z "${DISPLAY:-}" ]]; then
    if command -v xvfb-run >/dev/null 2>&1; then runner=(xvfb-run -a); else echo "ERROR: no hay DISPLAY ni xvfb-run para correr el QA de Linux" >&2; exit 4; fi
  fi
  if ! "${runner[@]}" "$bin" -- --qa-screenshot; then
    echo "ERROR: el control de calidad de $bin fallo (textos sin traducir o el juego no arranco)." >&2
    exit 4
  fi
  echo "QA OK: $bin"
}

# QA del build web con Chrome headless (tools/web_qa.ps1): textos, raspadita y sobre con mouse, guardado al recargar.
qa_web_dir() {
  local dir="$1" port="$2"
  [[ $NO_QA -eq 1 ]] && { echo "QA web: salteado (--no-qa)"; return 0; }
  local ps=""
  if command -v powershell.exe >/dev/null 2>&1; then ps="powershell.exe -NoProfile -ExecutionPolicy Bypass"; elif command -v pwsh >/dev/null 2>&1; then ps="pwsh -NoProfile"; fi
  if [[ -z "$ps" ]]; then echo "QA web: salteado (hace falta PowerShell: powershell.exe o pwsh)"; return 0; fi
  echo "QA web: $dir ..."
  if ! $ps -File tools/web_qa.ps1 -Dir "$dir" -Port "$port"; then
    echo "ERROR: el QA web de $dir fallo (capturas en export/qa_web/)" >&2
    exit 6
  fi
}

for t in "${TARGETS[@]}"; do
  case "$t" in
    windows)      export_one "Windows Desktop" "export/windows/${NAME}.exe"; qa_windows_exe "export/windows/${NAME}.exe" ;;
    windows_demo) export_one "Windows Demo" "export/windows_demo/${NAME}Demo.exe"; qa_windows_exe "export/windows_demo/${NAME}Demo.exe" ;;
    linux)        export_one "Linux" "export/linux/${NAME}.x86_64"; qa_linux_bin "export/linux/${NAME}.x86_64" ;;
    web)          export_one "Web" "export/web/index.html" ;;
    web_demo)     export_one "Web Demo" "export/web_demo/index.html" ;;
    *) echo "Destino desconocido: $t (usá windows, windows_demo, linux, web o web_demo)" >&2; exit 1 ;;
  esac
  case "$t" in
    web|web_demo)
      dir="export/web"; [[ "$t" == "web_demo" ]] && dir="export/web_demo"
      for f in index.js index.wasm index.pck index.html; do
        [[ -s "$dir/$f" ]] || { echo "ERROR: falta $dir/$f" >&2; exit 3; }
      done
      echo "Build web OK ($dir)."
      qa_web_dir "$dir" "$([[ "$t" == "web" ]] && echo 8061 || echo 8062)"
      ;;
  esac
done
echo "Listo. Archivos en export/"
