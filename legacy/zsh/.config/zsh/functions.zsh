# Funções do dia a dia — espelho de fish/.config/fish/functions/.
#
# No zsh não existe diretório de autoload por arquivo como no fish; por isso
# tudo fica neste único arquivo, carregado pelo .zshrc.

# Herdr sempre abrindo uma aba nova na sessão padrão.
herdr() {
    # Dentro de um pane do Herdr (HERDR_ENV=1) só repassa pro binário real:
    # cada aba nova sobe um shell que roda esta função de novo, então criar
    # aba aqui dentro gera loop infinito de abas.
    if [[ ${HERDR_ENV-} == 1 ]]; then
        command herdr "$@"
        return
    fi

    # Servidor já de pé (não é o primeiro shell do dia) -> cria e foca
    # uma aba nova antes de anexar.
    if command herdr status server >/dev/null 2>&1; then
        command herdr tab create --focus >/dev/null
    fi

    command herdr "$@"
}

# Passa a usar SSH em todo clone do GitHub.
git-use-ssh() {
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo "✅ Git configurado: agora o GitHub usará SSH por padrão!"
}

# Remove a regra que força SSH e volta ao HTTPS padrão.
git-use-https() {
    git config --global --unset url."git@github.com:".insteadOf
    echo "♻️  Git resetado: voltando ao padrão original (HTTPS)."
}

# Clona de uma vez os repos da Cometa que interessam.
clone_repos_cometa() {
    gh repo list cometagaming --limit 1000 --json name -q '.[].name' \
        | grep -E '(-sdk|cometa-reports-api|infra-modules-iac)' \
        | xargs -P 4 -I {} gh repo clone cometagaming/{}
}
