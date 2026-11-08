# Funções do dia a dia.
#
# No zsh não existe diretório de autoload por arquivo como no fish; por isso
# tudo fica neste único arquivo, carregado pelo .zshrc.

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

# Podman com todas as GPUs NVIDIA via CDI. O SELinux do Fedora bloqueia os
# nós /dev/nvidia* para o tipo container_t, então label=disable é necessário.
# Para manter o contêiner depois (sem --rm), use `podman run` diretamente.
podman-gpu() {
    command podman run --rm --device nvidia.com/gpu=all \
        --security-opt=label=disable "$@"
}
