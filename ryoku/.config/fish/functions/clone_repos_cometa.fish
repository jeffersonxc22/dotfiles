function clone_repos_cometa --description 'Clona os repos da Cometa (sdk, reports-api, infra-modules-iac)'
    gh repo list cometagaming --limit 1000 --json name -q '.[].name' \
        | grep -E '(-sdk|cometa-reports-api|infra-modules-iac)' \
        | xargs -P 4 -I {} gh repo clone cometagaming/{}
end
