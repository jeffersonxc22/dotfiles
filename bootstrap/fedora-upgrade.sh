#!/usr/bin/env bash
# Atualiza o Fedora para a próxima release, sem versão fixa no código.
#
# Uso:
#   ./bootstrap/fedora-upgrade.sh --check   # só mostra a release de destino
#   ./bootstrap/fedora-upgrade.sh           # baixa e pergunta antes de reiniciar
#
# O destino é sempre current+1, calculado com o rpm do sistema. Assim o mesmo
# script serve para 44→45, 45→46, etc.
set -euo pipefail

current="$(rpm -E %fedora)"
if [[ ! $current =~ ^[0-9]+$ ]]; then
    echo "ERRO: não foi possível descobrir a release atual (rpm -E %%fedora = '$current')." >&2
    exit 1
fi
target=$((current + 1))

echo "Fedora atual: $current"
echo "Destino:      $target"

if [[ ${1:-} == "--check" ]]; then
    exit 0
fi

if ! command -v dnf >/dev/null 2>&1; then
    echo "ERRO: dnf não encontrado." >&2
    exit 1
fi

if ! dnf system-upgrade --help >/dev/null 2>&1; then
    echo "ERRO: o plugin system-upgrade não está disponível (pacote dnf5-plugins)." >&2
    exit 1
fi

echo
echo "== Atualizando o Fedora $current antes do salto"
sudo dnf upgrade --refresh -y

echo
echo "== Baixando o Fedora $target"
sudo dnf system-upgrade download --releasever="$target"

echo
read -rp "Reiniciar agora para concluir a atualização? [s/N] " answer
if [[ ${answer:-N} =~ ^[SsYy]$ ]]; then
    sudo dnf system-upgrade reboot
else
    echo "Tudo baixado. Quando quiser aplicar: sudo dnf system-upgrade reboot"
fi
