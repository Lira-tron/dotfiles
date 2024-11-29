SHELL = /bin/bash
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
UNAME_S := $(shell uname -s)


BREW_PACKAGES        := stow tmux xclip ripgrep wget jq fd lua-language-server eza zoxide autojump lsd bat tree htop miller glow lazygit node helm kubectl derailed/k9s/k9s awscli neovim yaml-language-server go yq fzf mvn gotests alacritty powerlevel10k zsh-vi-mode zsh-autosuggestions zsh-syntax-highlighting thefuck zsh-history-substring-search pandoc joshmedeski/sesh/sesh reattach-to-user-namespace xsel

all:: install-brew-packages link install-terminfo

link::
	stow --verbose --no-folding --target=$$HOME --dir=$(DIR) --restow home


unlink::
	stow --verbose --no-folding --target=$$HOME --dir=$(DIR) --delete home


install-brew-packages:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install $(BREW_PACKAGES)
	brew tap homebrew/cask-fonts
	brew install font-meslo-lg-nerd-font
	brew install font-jetbrains-mono
	brew install --cask --no-quarantine syntax-highlight
	brew install --cask wezterm


install-terminfo:
	curl -LO https://invisible-island.net/datafiles/current/terminfo.src.gz && gunzip terminfo.src.gz && \
	/usr/bin/tic -xe tmux-256color terminfo.src

