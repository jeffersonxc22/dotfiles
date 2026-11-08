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

# O toolkit injeta o driver e as bibliotecas do host; sem o módulo carregado
# não há o que configurar. O install.sh roda drivers.sh antes desta etapa.
if ! command -v nvidia-smi >/dev/null || ! nvidia-smi -L >/dev/null 2>&1; then
    echo "aviso: driver NVIDIA não está carregado; instale/ative com drivers.sh e rode de novo." >&2
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

# O CDI é gerado automaticamente desde o toolkit 1.18. Gerar uma vez garante
# que o dispositivo exista já nesta instalação, sem esperar o próximo boot.
if systemctl list-unit-files nvidia-cdi-refresh.path >/dev/null 2>&1; then
    sudo systemctl enable --now nvidia-cdi-refresh.path
    sudo systemctl enable --now nvidia-cdi-refresh.service || true
fi
if ! sudo test -s /var/run/cdi/nvidia.yaml; then
    sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml
fi

# CDI e o hook OCI da NVIDIA não devem coexistir (doc de CDI).
if [[ -e /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json ]]; then
    echo "== Removendo hook OCI NVIDIA (conflita com CDI)"
    sudo rm -f /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
fi

echo "== Dispositivos CDI disponíveis"
nvidia-ctk cdi list
echo
echo "Teste com: podman run --rm --device nvidia.com/gpu=all \\"
echo "  --security-opt=label=disable docker.io/library/ubuntu:24.04 nvidia-smi -L"
