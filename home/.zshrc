# Enable Powerrevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

#ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"


# https://unix.stackexchange.com/questions/599641/why-do-i-have-duplicates-in-my-zsh-history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

export HISTFILE=~/.zsh_history
export HISTSIZE=1000000000
export SAVEHIST=1000000000

# export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;-'

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude .bemol'
export FZF_CTRL_R_OPTS="--reverse --info hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export EDITOR='nvim'
export MANPAGER='nvim +Man!'

# Add wisely, as too many plugins slow down shell startup.
plugins=(
  aws
  autojump
  git
  brew
  kubectl
  # zsh-vi-mode
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  # command-time
)

source $ZSH/oh-my-zsh.sh

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
    [ -f $XDG_CONFIG_HOME/fzf/fzf.zsh ] && source $XDG_CONFIG_HOME/fzf/fzf.zsh

    bindkey '^P' history-beginning-search-backward
    bindkey '^N' history-beginning-search-forward
    bindkey '^ ' autosuggest-accept
}

zvm_after_init_commands+=(my_zvm_init)

bindkey -e
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

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

alias ll="lsd -alh"
alias ls="lsd -h --group-directories-first"

alias t='tmux'
alias tn='t new-session -As'

alias ff='/usr/local/bin/fd'

# using ripgrep combined with preview
# find-in-file - usage: fif <searchTerm>
fg() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --hidden --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}


# fd - cd to selected directory
fd() {

  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# fda - including hidden directories
fda() {
  local dir
  dir=$(find ${1:-.} -type d 2> /dev/null | fzf +m) && cd "$dir"
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

initsetup () {
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
  brew tap homebrew/cask-fonts
  brew install --cask font-jetbrains-mono
}


if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
