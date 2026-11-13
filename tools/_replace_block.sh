#!/usr/bin/env bash
# uso: _replace_block.sh archivo "patron_inicio" "patron_fin_exclusivo" archivo_nuevo
f="$1"; s=$(grep -n -m1 -- "$2" "$f" | cut -d: -f1); e=$(awk -v s="$s" -v p="$3" 'NR>s && index($0,p)==1 {print NR; exit}' "$f")
[[ -z "$s" || -z "$e" ]] && { echo "no encontre bloque ($s,$e)"; exit 1; }
{ head -n $((s-1)) "$f"; cat "$4"; echo; echo; tail -n +$e "$f"; } > "$f.new" && mv "$f.new" "$f" && echo "reemplazado $s..$((e-1))"
