#!/usr/bin/env bash
# NVIDIA Container Toolkit pelo repositório oficial + CDI para o Podman.
#
# O Podman usa CDI (Container Device Interface), o modo recomendado pela NVIDIA:
# não precisa configurar runtime nem instalar o hook OCI do Docker, e funciona
# também com Podman rootless. O serviço nvidia-cdi-refresh mantém
# /var/run/cdi/nvidia.yaml atualizado a cada boot e troca de driver.
#
# Doc: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html
#
# Uso: ./bootstrap/nvidia-container-toolkit.sh   (o install.sh chama; pode rodar sozinho)
set -euo pipefail

command -v lspci >/dev/null \
    || { echo "aviso: lspci ausente (pacote pciutils); pulando NVIDIA Container Toolkit." >&2; exit 0; }
if ! lspci -nn | grep -qE '\[03(00|02)\]: .*\[10de:'; then
    echo "== Sem GPU NVIDIA; nada a fazer."
    exit 0
fi

# Sem driver instalado não há o que configurar. Logo depois do drivers.sh o akmod
# ainda está compilando e o módulo só carrega no próximo boot: o toolkit é instalado
# assim mesmo, e o nvidia-cdi-refresh gera o CDI sozinho quando o driver subir.
if ! rpm -q akmod-nvidia >/dev/null 2>&1 && ! command -v nvidia-smi >/dev/null; then
    echo "aviso: driver NVIDIA não instalado; rode drivers.sh e depois este script." >&2
    exit 0
fi

if ! command -v podman >/dev/null; then
    sudo dnf install -y podman
fi

if ! rpm -q nvidia-container-toolkit >/dev/null 2>&1; then
    echo "== Repositório oficial do NVIDIA Container Toolkit"
    sudo curl -fsSL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
        -o /etc/yum.repos.d/nvidia-container-toolkit.repo
    sudo dnf install -y nvidia-container-toolkit
fi

# O CDI é gerado automaticamente desde o toolkit 1.18, a cada boot e troca de driver.
if systemctl list-unit-files nvidia-cdi-refresh.path >/dev/null 2>&1; then
    sudo systemctl enable --now nvidia-cdi-refresh.path
    sudo systemctl enable --now nvidia-cdi-refresh.service || true
fi
# CDI e o hook OCI da NVIDIA não devem coexistir (doc de CDI).
if [[ -e /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json ]]; then
    echo "== Removendo hook OCI NVIDIA (conflita com CDI)"
    sudo rm -f /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
fi

if ! nvidia-smi -L >/dev/null 2>&1; then
    echo "Toolkit instalado. O driver ainda não está carregado: reinicie e o CDI" \
        "(nvidia.com/gpu=all) é gerado no boot. Confira com: nvidia-ctk cdi list"
    exit 0
fi
# Gerar uma vez garante o dispositivo já nesta sessão, sem esperar o próximo boot.
if ! sudo test -s /var/run/cdi/nvidia.yaml; then
    sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml
fi
echo "== Dispositivos CDI disponíveis"
nvidia-ctk cdi list
echo
echo "Teste com: podman run --rm --device nvidia.com/gpu=all \\"
echo "  --security-opt=label=disable docker.io/library/ubuntu:24.04 nvidia-smi -L"
