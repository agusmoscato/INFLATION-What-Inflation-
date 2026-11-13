#!/usr/bin/env bash
# Exporta INFLATION? What Inflation? a Windows, Linux y Web en export/.
#
# Uso:
#   tools/export_all.sh                      # exporta los tres (requiere export templates instaladas)
#   tools/export_all.sh --install-templates  # baja e instala las templates de Godot (~1 GB) y exporta
#   tools/export_all.sh --check              # solo verifica que todo esté listo
#   tools/export_all.sh windows web          # exporta solo algunos
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
for a in "$@"; do
  case "$a" in
    --install-templates) install_templates ;;
    --check) CHECK_ONLY=1 ;;
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

TARGETS=("${ARGS[@]:-windows linux web}")
[[ ${#ARGS[@]} -eq 0 ]] && TARGETS=(windows linux web)

echo "Importando recursos..."
"$GODOT" --headless --import >/dev/null 2>&1 || true

export_one() {
  local preset="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  echo "Exportando '$preset' -> $out"
  "$GODOT" --headless --export-release "$preset" "$out"
  [[ -s "$out" ]] || { echo "ERROR: no se generó $out" >&2; exit 3; }
}

for t in "${TARGETS[@]}"; do
  case "$t" in
    windows) export_one "Windows Desktop" "export/windows/${NAME}.exe" ;;
    linux)   export_one "Linux" "export/linux/${NAME}.x86_64" ;;
    web)
      export_one "Web" "export/web/index.html"
      for f in index.js index.wasm index.pck; do
        [[ -s "export/web/$f" ]] || { echo "ERROR: falta export/web/$f" >&2; exit 3; }
      done
      echo "Build web OK. Para probarlo localmente (necesita servidor HTTP):"
      echo "  cd export/web && python3 -m http.server 8060   # y abrir http://localhost:8060"
      ;;
    *) echo "Destino desconocido: $t (usá windows, linux o web)" >&2; exit 1 ;;
  esac
done
echo "Listo. Archivos en export/"
