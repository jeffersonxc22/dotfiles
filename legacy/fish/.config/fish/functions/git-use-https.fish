function git-use-https --description 'Remove a regra de forçar SSH'
    git config --global --unset url."git@github.com:".insteadOf
    echo "♻️  Git resetado: Voltando ao padrão original (HTTPS)."
end
