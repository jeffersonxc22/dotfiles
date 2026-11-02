# Logitech MX Mechanical Mini com keyd

O arquivo `keyd/logitech.conf` é destinado a `/etc/keyd/logitech.conf`.
Ele identifica o teclado Bluetooth `046d:b367:1432f0af` e mantém o layout
brasileiro do KDE. O mapeamento é uma aproximação de US International: não
implementa todas as combinações AltGr e precisa de validação em uso.
Para `ç`, use AltGr+vírgula; com Shift, produz `Ç`. AltGr+C permanece
com o comportamento do layout brasileiro (`©`).

Na raiz dos dotfiles, verifique conflitos e crie o link separadamente do deploy
dos arquivos pessoais:

```sh
sudo stow --no-folding --simulate --verbose --target=/etc keyd
sudo stow --no-folding --target=/etc keyd
sudo keyd check /etc/keyd/logitech.conf
sudo systemctl enable --now keyd
```

Se o serviço já estiver ativo, aplique alterações com `sudo keyd reload`.
Para interromper e desativar o serviço: `sudo systemctl disable --now keyd`.
A sequência de emergência do keyd é Backspace + Esc + Enter. Para retirar o
link: `sudo stow --no-folding --delete --target=/etc keyd`.
