#!/usr/bin/env bash
# Layout de monitores: DP-1 (meio) como primária, DP-3 à direita e a tela do
# notebook (eDP-1) desligada enquanto o monitor do meio estiver conectado.
# Se DP-1 não estiver conectada, não mexe em nada (usa o padrão do Plasma).
set -euo pipefail

command -v kscreen-doctor >/dev/null 2>&1 || exit 0

# No login o backend do KScreen pode demorar um pouco para ver as saídas.
json=''
for _ in {1..20}; do
    json="$(kscreen-doctor --json 2>/dev/null || true)"
    [[ -n $json ]] && break
    sleep 0.5
done
[[ -n $json ]] || { echo "kscreen-doctor não respondeu; nada a fazer." >&2; exit 0; }

#Monta os argumentos só com o que está conectado (kscreen-doctor é atômico).
mapfile -t args < <(python3 -c '
import json, sys
outs = {o["name"]: o for o in json.load(sys.stdin)["outputs"]}
if not outs.get("DP-1", {}).get("connected"):
    sys.exit(0)
if outs.get("eDP-1", {}).get("enabled"):
    print("output.eDP-1.disable")
print("output.DP-1.primary")
print("output.DP-1.position.0,0")
if outs.get("DP-3", {}).get("connected"):
    print("output.DP-3.position.2560,0")
' <<<"$json")

if ((${#args[@]} == 0)); then
    echo "Monitor do meio (DP-1) não conectado; layout mantido."
    exit 0
fi

kscreen-doctor "${args[@]}"
echo "Monitores: DP-1 primária, DP-3 à direita, eDP-1 desligada."
