SHELL = /bin/bash
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
UNAME_S := $(shell uname -s)


BREW_PACKAGES        := stow tmux ripgrep wget jq fd lua-language-server eza zoxide autojump lsd bat tree htop miller glow lazygit node@20 helm kubectl derailed/k9s/k9s awscli neovim yaml-language-server go yq fzf mvn gotests alacritty powerlevel10k zsh-vi-mode zsh-autosuggestions zsh-syntax-highlighting thefuck zsh-history-substring-search pandoc

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

install-terminfo:
	curl -LO https://invisible-island.net/datafiles/current/terminfo.src.gz && gunzip terminfo.src.gz && \
	/usr/bin/tic -xe tmux-256color terminfo.src


setup-java:: download-jdtls download-checkstyle download-lombok download-google-java-format setup-java-debug setup-vscode-java-test setup-vscode-java-decompiler


download-jdtls:
	mkdir -p ~/.java && \
	cd ~/.java && \
	rm -rf ~/.java/jdtls && \
	mkdir -p jdtls && \
	wget https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.26.0/jdt-language-server-1.26.0-202307271613.tar.gz -O jdtls.tar.gz && \
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


download-zsh-plugins:
	rm -rf ~/.zsh && \
	mkdir -p ~/.zsh && \
	cd ~/.zsh && \
	for repo in $(ZSH_PLUGINS_PACKAGES); do \
		git clone --depth=1 https://github.com/$$repo.git; \
	done

update-zsh-plugins:
	cd ~/.zsh && \
	ls | xargs -I{} git -C {} pull
