# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# https://unix.stackexchange.com/questions/599641/why-do-i-have-duplicates-in-my-zsh-history

# setopt HIST_IGNORE_ALL_DUPS
# setopt HIST_FIND_NO_DUPS
# setopt HIST_SAVE_NO_DUPS
# setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000000
export SAVEHIST=1000000000

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
source $(brew --prefix)/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(thefuck --alias)"
eval "$(thefuck --alias fk)"

# export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;-'

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude .bemol'
export FZF_CTRL_R_OPTS="--reverse --info hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export EDITOR='nvim'
export MANPAGER='nvim +Man!'

function zvm_config() {
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
}

# https://github.com/jeffreytse/zsh-vi-mode/issues/19
# saves to clipboard on yank
function zvm_vi_yank() {
    zvm_yank
    printf %s "${CUTBUFFER}" | clipcopy
    zvm_exit_visual_mode
}

function my_zvm_init() {
    # [ -f $XDG_CONFIG_HOME/fzf/fzf.zsh ] && source $XDG_CONFIG_HOME/fzf/fzf.zsh

    bindkey -r '\e/'
    bindkey '^[[1;3C' forward-word
    bindkey '^[[1;3D' backward-word

    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down

    bindkey '^r' fzf-history-widget
}

zvm_after_init_commands+=(my_zvm_init)

function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessiond
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

# Directories
# workplace is a dir with work code
alias gS="cd ~/Code"
alias vim='nvim'
alias gt='gotests -all -w -parallel '

alias codein="code-insiders"
alias watch="watch "
alias kubesh='(){ kubectl run alpine-shell --rm -ti --image=alpine -n=$1 -- /bin/sh ;}'
alias k='kubectl'

alias checkPort='lsof -n -i'

alias lg='lazygit'
alias gb='git branch'
alias glo='git log --oneline'
alias gs='git status'

alias ll="eza -alh"
# alias ls="lsd -h --group-directories-first"
alias ls="eza --group-directories-first --color=always --long --no-filesize --icons=always --no-time --no-user --no-permissions"

alias cd="z"
alias cat="bat"

alias t='tmux'
alias tm='t new-session -As'
alias tc='sesh connect'
alias tn='sesh connect $(sesh list | fzf)'

alias sizeorder="du -ah . | grep -v "/$" | sort -rh"

# using ripgrep combined with preview
# find-in-file - usage: fif <searchTerm>
fg() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  selected_file=$(rg --files-with-matches --hidden --g '!.git/' --g '!.bemol/' --no-messages "$1"  | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --hidden --pretty --context 10 '$1' || rg --ignore-case --hidden --pretty --context 10 '$1' {}"); if [ -n "$selected_file" ]; then vim "$selected_file"; fi
}

fcd() {
   local file
   local dir
   file=$(fzf +m -q "$1") && dir=$(dirname "$file") && cd "$dir"
}

function extract {
 if [ $# -eq 0 ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz|.zlib|.cso>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 fi
    for n in "$@"; do
        if [ ! -f "$n" ]; then
            echo "'$n' - file doesn't exist"
            return 1
        fi

        case "${n%,}" in
          *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                       tar zxvf "$n"       ;;
          *.lzma)      unlzma ./"$n"      ;;
          *.bz2)       bunzip2 ./"$n"     ;;
          *.cbr|*.rar) unrar x -ad ./"$n" ;;
          *.gz)        gunzip ./"$n"      ;;
          *.cbz|*.epub|*.zip) unzip ./"$n"   ;;
          *.z)         uncompress ./"$n"  ;;
          *.7z|*.apk|*.arj|*.cab|*.cb7|*.chm|*.deb|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar|*.vhd)
                       7z x ./"$n"        ;;
          *.xz)        unxz ./"$n"        ;;
          *.exe)       cabextract ./"$n"  ;;
          *.cpio)      cpio -id < ./"$n"  ;;
          *.cba|*.ace) unace x ./"$n"     ;;
          *.zpaq)      zpaq x ./"$n"      ;;
          *.arc)       arc e ./"$n"       ;;
          *.cso)       ciso 0 ./"$n" ./"$n.iso" && \
                            extract "$n.iso" && \rm -f "$n" ;;
          *.zlib)      zlib-flate -uncompress < ./"$n" > ./"$n.tmp" && \
                            mv ./"$n.tmp" ./"${n%.*zlib}" && rm -f "$n"   ;;
          *.dmg)
                      hdiutil mount ./"$n" -mountpoint "./$n.mounted" ;;
          *)
                      echo "extract: '$n' - unknown archive method"
                      return 1
                      ;;
        esac
    done
}


reloadzsh () {
   test -f ~/.zshrc && . ~/.zshrc
}

if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# For ZSH users, uncomment the following two lines:
autoload -Uz +X compinit && compinit -C
autoload -Uz +X bashcompinit && bashcompinit

source <(kubectl completion zsh)

source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [ -f "$HOME/.p10k.zsh" ]; then
    source "$HOME/.p10k.zsh"
fi

# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false

export AWS_EC2_METADATA_DISABLED=true

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
