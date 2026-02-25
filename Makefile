SHELL = /bin/bash
export PATH := /opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$(PATH)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
UNAME_S := $(shell uname -s)

BREW_PACKAGES        := stow tmux xclip ripgrep wget jq fd eza zoxide autojump lsd bat tree htop miller glow lazygit helm kubectl derailed/k9s/k9s awscli neovim go yq fzf mvn gotests starship zsh-vi-mode zsh-autosuggestions zsh-syntax-highlighting thefuck zsh-history-substring-search pandoc joshmedeski/sesh/sesh xsel dust fastfetch git-delta imagemagick pkgconf libpng lua wordnet gh luarocks nvm atuin carapace tree-sitter-cli mas kotlin mise

MAC_HOME_PACKAGES := betterdisplay downie permute keycastr brave-browser loupedeck obs jump-desktop-connect appcleaner adguard backblaze calibre chatgpt discord iina

all:: install-brew-packages link

link::
	stow --verbose --no-folding --target=$$HOME --dir=$(DIR) --restow --ignore='.kiro/knowledge' --ignore='.gemini/knowledge' --ignore='.DS_Store' home
	[ -L ~/.kiro/knowledge ] || ln -s ~/Documents/knowledge ~/.kiro/knowledge
	[ -L ~/.kiro/knowledge/notes ] || ln -s ~/Documents/Notes ~/.kiro/knowledge/notes
	[ -L ~/.gemini/knowledge ] || ln -s ~/Documents/knowledge ~/.gemini/knowledge
	[ -L ~/.gemini/knowledge/notes ] || ln -s ~/Documents/Notes ~/.gemini/knowledge/notes
	stow --verbose --no-folding --target=$$HOME --dir=$(DIR) --restow --ignore='.kiro/knowledge' --ignore='.DS_Store' home

unlink::
	stow --verbose --no-folding --target=$$HOME --dir=$(DIR) --delete home

UNAME_S := $(shell uname -s)

install-brew-packages:
	command -v brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install $(BREW_PACKAGES)
ifeq ($(UNAME_S),Darwin)
	brew install font-jetbrains-mono
	brew install font-meslo-lg-nerd-font
	brew install reattach-to-user-namespace pngpaste trash
	brew tap RhetTbull/osxphotos
	brew install osxphotos
	brew install icloudpd
	brew install tw93/tap/mole
	brew install --cask --no-quarantine syntax-highlight
	brew install --cask ghostty
	brew install --cask mouseless
	brew install --cask neovide
	brew install --cask font-fira-code-nerd-font
	brew install --cask visual-studio-code
	brew install --cask raycast
	brew install --cask corretto
	brew install --cask corretto@21
	brew install --cask corretto@17
	brew install --cask corretto@11
	brew install --cask corretto@8
	# brew install --cask alacritty
	# brew install --cask wezterm
	# brew install --cask nikitabobko/tap/aerospace
	cd ~/.config/zsh/
	git clone https://github.com/Aloxaf/fzf-tab
	cd
endif

# Mac instructions
# For Raycast, System Settings -> keyboard -> keyboard Shortcuts -> Spotlight and unselect command space
# Go te Setting -> keyboard -> keyboard shortcuts -> Keyboard -> move focust to next window -> Set it to HyperN
# Go to settings Mission Control -> Shortcuts -> Remove C-up and C-down
# For better display 2388x1668, 1194x834, 1389x970 for ipad pro 11
# Install backblaze manually
# Install elgato software

install-mac::
	brew install --cask $(MAC_HOME_PACKAGES)

install-appstore::
	mas install 1502839586 # Hand mirror
	mas install 6446206067 # Klack
	mas install 572281534 # Transloader
	mas install 1533805339 # Keepa
	mas install 1480068668 # Messenger
	mas install 310633997 # Whatsapp
	mas install 6472865291 # ZSA Keymapp
	mas install 1475387142 # Tailscale
	mas install 694633015 # Keepsolid
	mas install 302584613 # Amazon Kindle
	mas install 457622435 # Yoink
	# mas install 414528154 # ScreenFloat

setup-java:: download-jdtls setup-java-debug setup-vscode-java-test setup-vscode-java-decompiler

download-jdtls:
	mkdir -p ~/.java && \
	cd ~/.java && \
	rm -rf ~/.java/jdtls && \
	mkdir -p jdtls && \
	wget https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.32.0/jdt-language-server-1.32.0-202402011424.tar.gz -O jdtls.tar.gz && \
	tar -xf jdtls.tar.gz -C jdtls

download-checkstyle:
	mkdir -p ~/.java && wget https://github.com/checkstyle/checkstyle/releases/download/checkstyle-8.41/checkstyle-8.41-all.jar -O ~/.java/checkstyle.jar

download-lombok:
	mkdir -p ~/.java && wget https://projectlombok.org/downloads/lombok.jar -O ~/.java/lombok.jar

download-google-java-format:
	mkdir -p ~/.java && wget https://github.com/google/google-java-format/releases/download/v1.15.0/google-java-format-1.15.0-all-deps.jar -O ~/.java/google-java-format.jar

setup-java-debug:
	mkdir -p ~/.java && \
	cd ~/.java && \
	rm -rf ~/.java/java-debug && \
	git clone --depth 1 https://github.com/microsoft/java-debug.git
	cd ~/.java/java-debug && \
	./mvnw clean install

setup-vscode-java-test:
	mkdir -p ~/.java && \
	cd ~/.java && \
	rm -rf ~/.java/vscode-java-test && \
	git clone --depth 1 https://github.com/microsoft/vscode-java-test.git
	cd ~/.java/vscode-java-test && \
	npm install && \
	npm run build-plugin

setup-vscode-java-decompiler:
	mkdir -p ~/.java && \
	cd ~/.java && \
	rm -rf ~/.java/vscode-java-decompiler && \
	git clone --depth 1 https://github.com/dgileadi/vscode-java-decompiler.git

install-terminfo:
	curl -LO https://invisible-island.net/datafiles/current/terminfo.src.gz && gunzip terminfo.src.gz && \
	/usr/bin/tic -xe tmux-256color terminfo.src

