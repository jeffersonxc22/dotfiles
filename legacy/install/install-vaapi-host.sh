#!/bin/bash
# Instala o driver VA-API da Intel (iHD) no host.
#
# Sem esse driver, o Chrome tenta VA-API e falha com
#   "vaInitialize failed: unknown libva error"
# e o decode de video fica em software (mais CPU, mais bateria, mais aquecimento).
#
# Uso: sudo bash /tmp/opencode/install-vaapi-host.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "ERRO: execute com sudo: sudo bash $0" >&2
    exit 1
fi

echo "=============================================================="
echo " 1. Instalando driver iHD + vainfo"
echo "=============================================================="
apt-get update
apt-get install -y vainfo intel-media-va-driver-non-free

# Opcional: VA-API sobre NVIDIA (NVDEC). Nao e necessario para reunioes
# (o ideal e decodificar na Intel, que gasta menos bateria) e o Chrome
# nao usa bem esse caminho. Descomente se quiser testar.
# apt-get install -y libnvidia-vaapi-driver

echo
echo "=============================================================="
echo " 2. Verificando VA-API"
echo "=============================================================="
vainfo | sed -n '1,35p'

echo
echo "=============================================================="
echo " 3. Estado esperado"
echo "=============================================================="
echo "- Driver: Intel iHD"
echo "- Decode: H.264, VP8, VP9, HEVC, AV1"
echo "- Encode: H.264, HEVC, VP9 (entrypoints EncSlice)"
echo
echo "IMPORTANTE: feche TODAS as janelas do Chrome e abra de novo"
echo "(o processo GPU so carrega o driver na inicializacao)."
echo "Depois confira em chrome://gpu a secao 'Video Acceleration Information'."
