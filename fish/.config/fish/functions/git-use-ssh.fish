function git-use-ssh --description 'Configura o Git para sempre trocar HTTPS por SSH no GitHub'
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo "✅ Git configurado: Agora o GitHub usará SSH por padrão!"
end
