#!/usr/bin/env fish

echo "Setting up Fish shell with Fisher..."

# Install Fisher if not already installed
if not functions -q fisher
    echo "Installing Fisher..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
else
    echo "Fisher already installed"
end

# Install plugins from fish_plugins file
if test -f ~/.config/fish/fish_plugins
    echo "Installing plugins from fish_plugins..."
    fisher update
else
    echo "No fish_plugins file found, installing essential plugins..."
    fisher install PatrickF1/fzf.fish
    fisher install jethrokuan/z
    fisher install edc/bass
    fisher install franciscolourenco/done
    fisher install jorgebucaran/autopair.fish
end

echo "Fish setup complete!"
echo "You may need to restart your terminal or run 'exec fish' to see all changes."
