# root/

> **Só Arch.** Este diretório conserta o mkinitcpio/UKI e o `nvidia.conf` que o
> instalador do Arch escreve. No Fedora o Ryoku usa dracut, mantém o bootloader
> da casa e deixa a NVIDIA no nouveau; no Void o initramfs também é outro. Lá,
> pule este pacote — `apply.sh` recusa rodar fora do Arch.

O que a hibernação do Ryoku precisa e vive **fora de `$HOME`** — arquivos de
root, que o `stow` não entrega. Nada aqui é aplicado sozinho: rode com sudo.

```sh
sudo ./root/apply.sh
```

`apply.sh` é idempotente: se já está tudo certo, ele não escreve nada e não
reconstrói o initramfs. Se mexer em algo, reconstrói a UKI e confere.

## Por que isso existe

O `ryoku-shell` mantém um inhibitor `block` de sleep de propósito ("route
suspend through a compositor-secure session lock"). Hibernar exige
`systemctl hibernate -i`, e isso falha em dois pontos independentes:

| Camada | Sintoma | Causa | Correção |
|---|---|---|---|
| polkit | `Operation denied due to active block inhibitor` | `hibernate-ignore-inhibit` é `auth_admin_keep` e o diálogo da ilha não entrega a senha com a sessão trancada — que é o fluxo do desktop (`lock` e depois hibernar) | regra local liberando **só** essa ação para usuário local/ativo em `wheel` |
| initramfs | `PM: hibernation: resume failed (-5)` e boot limpo | o `nvidia.conf` do instalador força `nvidia.ko` no initramfs; ele carrega ~2 ms antes do resume e o `nv_pmops_freeze` devolve `-EIO` | comentar o `MODULES=` e reconstruir a UKI |

A tela desta máquina é o `i915` (Intel); a RTX 5050 é dGPU híbrida e carrega
depois, em userspace. Tirar a NVIDIA do initramfs não muda o boot gráfico.

## Fluxo correto para hibernar

```sh
ryoku-shell lock && systemctl hibernate -i
```

É exatamente o que o botão de hibernar do desktop faz. Sem a regra polkit acima,
o `-i` abre um pedido de senha que não pode ser respondido com a tela trancada.

## Conferir

```sh
# a regra polkit vale? (deve responder result=yes, sem prompt)
pkcheck --action-id org.freedesktop.login1.hibernate-ignore-inhibit --process $$

# o initramfs está limpo? (deve dar 0)
lsinitcpio /boot/EFI/Linux/ryoku_linux.efi | grep -c extramodules/nvidia

# o resume aponta para o swap certo?
cat /sys/power/resume /sys/power/resume_offset
```

Ciclo validado: `hibernation entry` → desliga → `hibernation exit` no **mesmo
boot id**, swap de volta a 0 B. Os erros `spd5118 … returns -6` na retomada são
transitórios — os sensores de DIMM religam depois.

## Depois de update de kernel ou de driver

O `nvidia.conf` **não pertence a pacote nenhum**: foi escrito pelo instalador.
Se o Ryoku reescrever esse drop-in, o `resume failed (-5)` volta. Rodar
`sudo ./root/apply.sh` de novo resolve, e a conferência acima acusa o problema.

## Rollback

```sh
sudo cp -a /etc/mkinitcpio.conf.d/nvidia.conf.bak-* /etc/mkinitcpio.conf.d/nvidia.conf
sudo ryoku-host initramfs rebuild
sudo rm /etc/polkit-1/rules.d/49-ryoku-hibernate.rules
```

O rollback traz a falha de volta: ele existe para o caso de a UKI sem NVIDIA não
bootar. O menu do limine tem o submenu `Snapshots` como rede de segurança.
