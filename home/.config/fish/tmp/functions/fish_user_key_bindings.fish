function fish_user_key_bindings
    # Emacs-style bindings
    bind \cf forward-char
    bind \cb backward-char
    bind \ca beginning-of-line
    bind \ce end-of-line
    bind \ck kill-line
    bind \cy yank
    bind \ct transpose-chars
    bind \cw backward-kill-word
    bind \e\[3\;5~ kill-word
    
    # Alt+f and Alt+b for word movement
    bind \ef forward-word
    bind \eb backward-word
    
    # FZF bindings
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end
    
    # Atuin bindings
    if command -q atuin
        bind \cr _atuin_search
        bind -k up _atuin_bind_up
    end
end
