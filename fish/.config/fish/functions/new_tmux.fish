function new_tmux
    set session_dir (zoxide query --list | fzf)
    or return  # sai se fzf for cancelado

    set session_name (basename $session_dir)

    if tmux has-session -t $session_name 2>/dev/null
        if set -q TMUX
            tmux switch-client -t $session_name
        else
            tmux attach -t $session_name
        end
        set notification "tmux attached to $session_name"
    else
        if set -q TMUX
            tmux new-session -d -c $session_dir -s $session_name
            and tmux switch-client -t $session_name
            set notification "new tmux session INSIDE TMUX: $session_name"
        else
            tmux new-session -c $session_dir -s $session_name
            set notification "new tmux session: $session_name"
        end
    end

    if test -n "$session_name"
        notify-send $notification
    end
end

alias tm=new_tmux
