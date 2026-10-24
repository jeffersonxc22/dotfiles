#!/bin/bash
# Reaplica os módulos NVIDIA 615 ASSINADOS pela Canonical após uma
# atualização do kernel snap (pc-kernel). Deve ser rodado após o reboot
# no kernel novo.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "ERRO: execute com sudo: sudo bash $0" >&2
    exit 1
fi

KVER="$(uname -r)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "Kernel em execução: $KVER"
echo "Baixando linux-modules-nvidia-615-open-$KVER ..."
if ! apt-get download "linux-modules-nvidia-615-open-$KVER"; then
    echo "ERRO: o pacote assinado para o kernel $KVER ainda não está no repositório." >&2
    echo "Tente novamente mais tarde ou verifique: apt-cache policy linux-modules-nvidia-615-open-$KVER" >&2
    exit 1
fi

DEB="$(ls linux-modules-nvidia-615-open-*.deb | head -1)"
dpkg-deb -x "$DEB" extract
SRC="$WORK/extract/lib/modules/$KVER/kernel/nvidia-615-open"

if [ ! -d "$SRC" ]; then
    echo "ERRO: o .deb não contém módulos para $KVER" >&2
    exit 1
fi

UPD="/lib/modules/$KVER/updates/nvidia-615-open"
COMP="/var/snap/pc-kernel/current/modules/$KVER/graphics"

install -d -m 0755 "$UPD"
install -m 0644 "$SRC"/*.ko "$UPD"/

if [ -d "$COMP" ]; then
    install -m 0644 "$SRC"/*.ko "$COMP"/
fi

for m in nvidia nvidia-drm nvidia-modeset nvidia-uvm nvidia-peermem; do
    printf '%-16s ' "$m"
    modinfo -F signer "$UPD/$m.ko"
done

depmod -a "$KVER"
modprobe nvidia || true
nvidia-smi || true
