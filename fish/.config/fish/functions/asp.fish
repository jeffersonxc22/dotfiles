function asp --description 'Troca o AWS_PROFILE de forma rápida'
    set -gx AWS_PROFILE $argv[1]
end
