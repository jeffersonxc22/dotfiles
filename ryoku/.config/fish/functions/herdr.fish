function herdr --description 'Herdr sempre abrindo uma aba nova na sessão padrão'
    # Dentro de um pane do Herdr (HERDR_ENV=1) só repassa para o binário real:
    # cada aba nova sobe um shell que roda esta função de novo, então criar
    # aba aqui dentro viraria loop.
    if test "$HERDR_ENV" = "1"
        command herdr $argv
        return
    end

    # Servidor já de pé (não é o primeiro shell do dia): cria e foca uma aba
    # nova antes de anexar.
    if command herdr status server >/dev/null 2>&1
        command herdr tab create --focus >/dev/null
    end

    command herdr $argv
end
