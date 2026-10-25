#!/usr/bin/env bash
# Aplica o que a hibernação do Ryoku precisa e vive fora de $HOME.
#
# Por que existe: os dois arquivos abaixo são de root, então o stow não os
# entrega. Sem eles a hibernação falha em pontos diferentes:
#
#   1. polkit    -> `systemctl hibernate -i` pede senha, e o diálogo da ilha
#                   não entrega a senha com a sessão trancada (o fluxo do
#                   desktop). Resultado: "Operation denied due to active block
#                   inhibitor" e a máquina não hiberna.
#   2. initramfs -> o nvidia.conf escrito pelo instalador força nvidia.ko no
#                   initramfs; ele carrega ~2 ms antes do resume e o
#                   nv_pmops_freeze devolve -EIO. Resultado: "resume failed
#                   (-5)" e boot limpo, com a sessão perdida.
#
# Uso:  sudo ./root/apply.sh
# Idempotente: rodar de novo não estraga nada e só reconstrói a UKI se o
# initramfs realmente mudou.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
uki_dirty=0   # só o que muda o initramfs dispara rebuild

if [[ $EUID -ne 0 ]]; then
    echo "rode com sudo: sudo $0" >&2
    exit 1
fi

echo "== 1. regra polkit (hibernate-ignore-inhibit) =="
rule_src="$here/etc/polkit-1/rules.d/49-ryoku-hibernate.rules"
rule_dst=/etc/polkit-1/rules.d/49-ryoku-hibernate.rules
if [[ ! -f $rule_src ]]; then
    echo "  FALHOU: $rule_src não existe"
    fail=1
elif cmp -s "$rule_src" "$rule_dst"; then
    echo "  já instalada, igual à do repo"
else
    install -Dm644 "$rule_src" "$rule_dst"
    echo "  instalada em $rule_dst"
fi

# polkitd vigia rules.d, então a regra vale na hora. Conferir pelo usuário que
# chamou o sudo: como root o subject seria outro (e root não está em wheel).
check_user="${SUDO_USER:-}"
if [[ -n $check_user ]]; then
    pk_out=$(runuser -u "$check_user" -- pkcheck \
        --action-id org.freedesktop.login1.hibernate-ignore-inhibit 2>&1)
else
    pk_out=$(pkcheck \
        --action-id org.freedesktop.login1.hibernate-ignore-inhibit 2>&1)
fi
if grep -q 'result=yes' <<<"$pk_out"; then
    echo "  pkcheck: result=yes (sem prompt)"
else
    echo "  sem confirmação automática de pkcheck; confira na sua sessão:"
    echo "    pkcheck --action-id org.freedesktop.login1.hibernate-ignore-inhibit --process \$\$"
    echo "  resposta esperada: polkit.result=yes"
fi

echo
echo "== 2. NVIDIA fora do initramfs =="
conf=/etc/mkinitcpio.conf.d/nvidia.conf
if [[ ! -f $conf ]]; then
    echo "  $conf não existe (sem ele a NVIDIA já não entra no initramfs)"
elif grep -qE '^MODULES=.*nvidia' "$conf"; then
    backup="$conf.bak-$(date +%Y%m%d-%H%M%S)"
    cp -a "$conf" "$backup"
    sed -i 's/^MODULES=/#MODULES=/' "$conf"
    echo "  MODULES= comentado (backup: $backup)"
    uki_dirty=1
else
    echo "  MODULES= já está comentado"
fi

if (( uki_dirty )); then
    echo "  reconstruindo a UKI…"
    if ! ryoku-host initramfs rebuild; then
        echo "  ryoku-host falhou; tentando mkinitcpio -P"
        if ! mkinitcpio -P; then
            echo "  FALHOU: rebuild do initramfs. A UKI anterior segue intacta."
            fail=1
        fi
    fi
fi

echo
echo "== 3. conferência =="
uki="$(ls /boot/EFI/Linux/*.efi 2>/dev/null | head -1)"
if [[ -z $uki ]]; then
    echo "  ATENÇÃO: nenhuma UKI em /boot/EFI/Linux/"
    fail=1
else
    printf '  UKI: %s (%s)\n' "$uki" "$(ls -lh "$uki" | awk '{print $5}')"
    n=$(lsinitcpio "$uki" 2>/dev/null | grep -c 'extramodules/nvidia')
    i=$(lsinitcpio "$uki" 2>/dev/null | grep -c i915)
    printf '  nvidia no initramfs (esperado 0): %s\n' "$n"
    printf '  i915 no initramfs (esperado >0): %s\n' "$i"
    (( n > 0 )) && fail=1
    (( i == 0 )) && fail=1
fi

echo
if (( fail )); then
    echo "== terminou com pendência: leia as linhas acima =="
    exit 1
fi
echo "== ok =="
(( uki_dirty )) && echo "UKI reconstruída: o próximo boot já usa a nova."
exit 0
