function asp --description 'Troca o AWS_PROFILE de forma rápida'
    if test (count $argv) -eq 0
        # Se não passar argumentos, lista os perfis disponíveis no seu ~/.aws/config
        echo "Perfis disponíveis:"
        grep '\[profile' ~/.aws/config | sed -e 's/\[profile //g' -e 's/\]//g'
        return
    end
    
    set -gx AWS_PROFILE $argv[1]
    echo "Configurado: AWS_PROFILE=$AWS_PROFILE"
    
    # Opcional: Se você usa o Starship, ele detectará a mudança automaticamente.
    # Se quiser forçar o check da identidade:
    # aws sts get-caller-identity --query "Arn" --output text
end
