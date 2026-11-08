#!/usr/bin/env bash
# Codecs, decodificação de vídeo por hardware e driver NVIDIA no Fedora,
# conforme as GPUs que o lspci encontra (doc: rpmfusion.org/Howto).
#
# Uso: ./bootstrap/drivers.sh   (o install.sh chama; pode rodar sozinho)
#
# NVIDIA só com confirmação e sempre pelo akmod-nvidia do RPM Fusion (módulos
# open por padrão), nunca pelo .run do site: ele quebra a cada kernel novo.
set -euo pipefail

command -v lspci >/dev/null || { echo "aviso: lspci ausente (pacote pciutils); pulando drivers." >&2; exit 0; }
gpu() { lspci -nn | grep -qE "\[03(00|02)\]: .*\[$1:"; } # gpu <vendor-id PCI>

echo "== Codecs (RPM Fusion)"
rpm -q ffmpeg >/dev/null 2>&1 || sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf install -y @multimedia --setopt=install_weak_deps=False --exclude=PackageKit-gstreamer-plugin

if gpu 8086; then
    echo "== Vídeo por hardware (Intel)"
    sudo dnf install -y intel-media-driver
fi

if gpu 10de; then
    echo "== NVIDIA"
    if version="$(modinfo -F version nvidia 2>/dev/null)"; then
        echo "  driver já instalado ($version); nada a fazer."
    elif mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
        echo "aviso: Secure Boot ativo; o módulo NVIDIA precisa ser assinado antes." \
            "Siga https://rpmfusion.org/Howto/Secure%20Boot e rode este script de novo." >&2
    elif [[ ! -t 0 ]]; then
        echo "  sem terminal interativo; rode ./bootstrap/drivers.sh para instalar o driver."
    else
        read -rp "Instalar o driver NVIDIA (akmod-nvidia, módulos open)? [s/N] " answer
        if [[ ${answer:-N} =~ ^[SsYy]$ ]]; then
            sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver
            sudo dnf mark user akmod-nvidia # evita que o autoremove do dnf5 leve o driver
            echo "  O akmod compila em segundo plano (até 5 min). Reinicie só quando" \
                "'modinfo -F version nvidia' mostrar a versão."
        fi
    fi
fi
