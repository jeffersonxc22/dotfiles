function git-use-https --description 'Remove a regra que força SSH no GitHub'
    git config --global --unset url."git@github.com:".insteadOf
    echo "♻️  Git de volta ao padrão (HTTPS)."
end
