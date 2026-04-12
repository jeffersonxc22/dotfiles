function new_tmux
    set session_name "home-"(date +%H%M%S)
    exec tmux new-session -c $HOME -s $session_name
end
