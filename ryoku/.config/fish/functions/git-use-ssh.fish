function git-use-ssh --description 'Faz o git trocar HTTPS por SSH no GitHub'
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo "✅ GitHub agora usa SSH por padrão."
end
