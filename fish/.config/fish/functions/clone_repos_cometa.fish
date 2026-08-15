function clone_repos_cometa
    gh repo list cometagaming --limit 1000 --json name -q '.[].name' \
                | grep -E '(-sdk|cometa-reports-api|infra-modules-iac)' \
                | xargs -P 4 -I {} gh repo clone cometagaming/{}
end
