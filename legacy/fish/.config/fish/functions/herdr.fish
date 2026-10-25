function herdr --description 'Herdr sempre abrindo uma aba nova na sessão padrão'
    # Se já estamos dentro de um pane do Herdr (HERDR_ENV=1), não faz
    # nada além de repassar pro binário real — cada aba nova também
    # sobe um shell que roda essa function de novo, então criar aba
    # aqui dentro gera loop infinito de abas.
    if test "$HERDR_ENV" = "1"
        command herdr $argv
        return
    end

    # Servidor já de pé (não é o primeiro shell do dia) -> cria e foca
    # uma aba nova antes de anexar.
    if command herdr status server >/dev/null 2>&1
        command herdr tab create --focus >/dev/null
    end

    command herdr $argv
end
