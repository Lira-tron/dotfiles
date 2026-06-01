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

# Cache brew prefix
export BREW_PREFIX=${HOMEBREW_PREFIX:-$(brew --prefix)}
export FPATH="$BREW_PREFIX/share/zsh/site-functions:${FPATH}"

autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

source ~/.config/zsh/fzf-tab/fzf-tab.plugin.zsh
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# source $BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh
source $BREW_PREFIX/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

eval "$(tv init zsh)"
# source <(fzf --zsh)
eval "$(mise activate zsh)"

# Lazy load
thefuck() {
  unfunction thefuck
  eval $(command thefuck --alias)
  eval $(command thefuck --alias fk)
  thefuck "$@"
}
fk() { thefuck "$@"; }

export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"


# export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;-'

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude .bemol'
export FZF_CTRL_R_OPTS="--reverse --info hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export EDITOR='nvim'
export MANPAGER='nvim +Man!'

ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

# # https://github.com/jeffreytse/zsh-vi-mode/issues/19
# # saves to clipboard on yank
# function zvm_vi_yank() {
#     zvm_yank
#     printf %s "${CUTBUFFER}" | clipcopy
#     zvm_exit_visual_mode
# }

_tv_zsh_history() {
  emulate -L zsh
  zle -I
  local output key cmd
  output=$(tv zsh-history --input "$LBUFFER" --inline --expect "ctrl-e")
  zle reset-prompt
  if [[ -n $output ]]; then
    # If ctrl-e was pressed, first line is "ctrl-e", second is the command
    # If enter was pressed, first line is empty, second is the command
    key=$(head -1 <<< "$output")
    cmd=$(tail -1 <<< "$output")
    RBUFFER=""
    LBUFFER="$cmd"
    if [[ "$key" != "ctrl-e" ]]; then
      zle accept-line
    fi
  fi
}
zle -N tv-zsh-history _tv_zsh_history

function zvm_after_init() {
  bindkey -r '\e/'
  bindkey '^[f' forward-word
  bindkey '^[b' backward-word

  # bindkey '^[[A' history-substring-search-up
  # bindkey '^[[B' history-substring-search-down

  # bindkey '^r' fzf-history-widget

  bindkey '^[[A' atuin-up-search
  bindkey '^[OA' atuin-up-search

  bindkey '^r' tv-zsh-history
  bindkey '^T' tv-smart-autocomplete

  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

}


# Directories
# workplace is a dir with work code
alias gS="cd ~/Code"
alias vim='nvim'
alias gt='gotests -all -w -parallel '

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


alias sizeorder="du -ah . | grep -v "/$" | sort -rh"

# Disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"
function precmd () {
  echo -ne "\033]0;$(print -rD $PWD)\007"
}
precmd

function preexec () {
  if [[ $1 =~ ^ssh ]]; then
    print -Pn "\e]0; 🚨🚨🚨$(print -rD $PWD) $1 🚨🚨🚨\a"
  else
    print -Pn "\e]0;🚀 $(print -rD $PWD) $1  🚀\a"
  fi
}


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

function gitPull() {
    local conflicts=()
    local current_dir=$(pwd)

    # Check current directory first
    if [[ -d ".git" ]]; then
        echo "Processing: ."
        git pull --rebase 2>&1 | tee /tmp/git_output
        if [[ ${PIPESTATUS[0]} -ne 0 ]] || grep -q "CONFLICT\|Automatic merge failed\|unmerged files\|fatal:" /tmp/git_output; then
            conflicts+=(".")
        fi
        echo ""
    fi

    # Check subdirectories
    for dir in */; do
        if [[ -d "$dir/.git" ]]; then
            echo "Processing: $dir"
            cd "$dir"

            git pull --rebase 2>&1 | tee /tmp/git_output
            if [[ ${PIPESTATUS[0]} -ne 0 ]] || grep -q "CONFLICT\|Automatic merge failed\|unmerged files\|fatal:" /tmp/git_output; then
                conflicts+=("$dir")
            fi

            cd "$current_dir"
            echo ""
        fi
    done

    echo "=== SUMMARY ==="
    if [[ ${#conflicts[@]} -eq 0 ]]; then
        echo "All repositories updated successfully!"
    else
        echo "Issues found in ${#conflicts[@]} folder(s):"
        for folder in "${conflicts[@]}"; do
            echo "  - $folder"
            echo "    cd $folder"
        done
    fi
}


reloadzsh () {
   test -f ~/.zshrc && . ~/.zshrc
}

function setJava () {
   if [ $1 -eq 8 ]; then
     export JAVA_HOME=$JAVA_HOME_8
   fi

   if [ $1 -eq 11 ]; then
     export JAVA_HOME=$JAVA_HOME_11
   fi

   if [ $1 -eq 17 ]; then
     export JAVA_HOME=$JAVA_HOME_17
   fi

   if [ $1 -eq 0 ]; then
     export JAVA_HOME=$JAVA_HOME_LATEST
   fi

   ln -sf $JAVA_HOME/bin/java $HOMEBREW_PREFIX/bin/java
   ln -sf $JAVA_HOME/bin/javac $HOMEBREW_PREFIX/bin/javac
   ln -sf $JAVA_HOME/bin/javadoc $HOMEBREW_PREFIX/bin/javadoc
   ln -sf $JAVA_HOME/bin/javap $HOMEBREW_PREFIX/bin/javap

}

alias ed='claude'
alias edrev='claude --agent reviewer'
alias edgenr='claude -r'
alias edcode='ralph run --config /Users/limonoct/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/ai/ralph/tdd-implementer.yml -p '
alias edplan='claude --agent planner'
alias edplanr='claude --agent planner --r'
alias edtech='claude --agent writer'
alias edtechr='claude --agent writer --r'
alias edtechn='_claude_pretty --agent writer -p "$@";'
alias edops='ed --agent ops'
alias edopsr='ed --agent ops -r'
alias edopsn='_claude_pretty --agent ops -p '
alias edcom='CLAUDE_SKIP_SESSION_HISTORY=1 claude --agent committer'
edcomn() { CLAUDE_SKIP_SESSION_HISTORY=1 _claude_pretty --agent committer -p "$@"; }

# Pretty-prints `claude -p` stream-json output as human-readable lines
# Shows: thinking, text, tool calls (with command/file/pattern), tool results
_claude_pretty() {
  claude --output-format stream-json --verbose --include-partial-messages "$@" | \
  jq -r '
    if .type=="assistant" then
      .message.content[]? |
      if .type=="text" then "🤖 " + .text
      elif .type=="thinking" then "💭 " + .thinking
      elif .type=="tool_use" then
        "🔧 " + .name + ": " + (
          if .name=="Bash" then .input.command
          elif .name=="Read" then
            .input.file_path +
            (if .input.offset then " (lines " + (.input.offset|tostring) +
              "–" + ((.input.offset + (.input.limit // 2000))|tostring) + ")"
             else "" end)
          elif .name=="Edit" then
            .input.file_path + "  [" +
            ((.input.old_string // "") | .[0:40] | gsub("\n";"⏎")) +
            " → " +
            ((.input.new_string // "") | .[0:40] | gsub("\n";"⏎")) + "]"
          elif .name=="Write" then
            .input.file_path + " (" + ((.input.content // "") | length | tostring) + " chars)"
          elif .name=="Glob" then .input.pattern + (if .input.path then " in " + .input.path else "" end)
          elif .name=="Grep" then
            "\"" + .input.pattern + "\"" +
            (if .input.path then " in " + .input.path else "" end) +
            (if .input.glob then " [" + .input.glob + "]" else "" end)
          elif .name=="WebFetch" then .input.url
          elif .name=="Agent" then .input.description + " (" + (.input.subagent_type // "general") + ")"
          elif .name=="Skill" then .input.skill + (if .input.args then " " + .input.args else "" end)
          else (.input | tostring | .[0:200]) end
        )
      else empty end
    elif .type=="user" then
      .message.content[]? |
      if .type=="tool_result" then
        "📥 " + (.content | if type=="array" then (.[0].text // "") else tostring end | .[0:300] | gsub("\n"; " ⏎ "))
      else empty end
    else empty end
  '
}

if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

eval "$(starship init zsh)"

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37m-%d\e[m'
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# prefix query to search
zstyle ':fzf-tab:*' query-string prefix first
source <(carapace _carapace)

[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

eval "$(zoxide init zsh)"
