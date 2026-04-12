function tmux_switch
    set session_dir (zoxide query --list | fzf)
    or return

    set session_name (basename $session_dir)

    if tmux has-session -t $session_name 2>/dev/null
        tmux switch-client -t $session_name
    else
        tmux new-session -d -c $session_dir -s $session_name
        tmux switch-client -t $session_name
    end

    notify-send "tmux: $session_name"
end
