#!/bin/bash
# Install dotfiles onto a vanilla Omarchy setup
# Usage: ./install.sh

set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES"

# Install packages
echo "Installing packages..."
yay -S --needed --noconfirm kitty slack-desktop kanata-bin zsh

# Install oh-my-zsh + plugins + powerlevel10k
if [ ! -d ~/.oh-my-zsh ]; then
  echo "Installing oh-my-zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "Installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Symlink .zshrc
ln -sf "$DOTFILES/zsh/.zshrc" ~/.zshrc
echo "  .zshrc -> linked"
ln -sf "$DOTFILES/zsh/.p10k.zsh" ~/.p10k.zsh
echo "  .p10k.zsh -> linked"

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$USER"
fi

# Set kitty as default terminal
echo "Setting kitty as default terminal..."
omarchy-install-terminal kitty

# Symlink hyprland configs
for f in looknfeel.conf bindings.conf input.conf monitors.conf autostart.conf hyprland.conf; do
  if [ -f "$DOTFILES/hypr/$f" ]; then
    ln -sf "$DOTFILES/hypr/$f" ~/.config/hypr/"$f"
    echo "  hypr/$f -> linked"
  fi
done

# Symlink waybar configs
for f in config.jsonc style.css; do
  if [ -f "$DOTFILES/waybar/$f" ]; then
    ln -sf "$DOTFILES/waybar/$f" ~/.config/waybar/"$f"
    echo "  waybar/$f -> linked"
  fi
done

# Symlink kitty config
if [ -f "$DOTFILES/kitty/kitty.conf" ]; then
  ln -sf "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
  echo "  kitty/kitty.conf -> linked"
fi

# Set up Chromium coding profile
if [ ! -f ~/.config/chromium-coding/Default/Preferences ]; then
  mkdir -p ~/.config/chromium-coding/Default
  cp "$DOTFILES/chromium-coding/Default/Preferences" ~/.config/chromium-coding/Default/Preferences
  echo "  chromium-coding profile -> created"
fi

# Kanata keyboard remapper
mkdir -p ~/.config/kanata
ln -sf "$DOTFILES/kanata/kanata.kbd" ~/.config/kanata/kanata.kbd
echo "  kanata/kanata.kbd -> linked"

sudo tee /etc/systemd/system/kanata.service > /dev/null << SVCEOF
[Unit]
Description=Kanata keyboard remapper
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/kanata -c /home/$USER/.config/kanata/kanata.kbd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
SVCEOF
sudo systemctl daemon-reload
sudo systemctl enable --now kanata.service
echo "  kanata.service -> enabled"

# Install scripts to PATH
mkdir -p ~/.local/bin
for script in "$DOTFILES"/bin/omarchy-*; do
  [ -f "$script" ] || continue
  ln -sf "$script" ~/.local/bin/"$(basename "$script")"
  echo "  $(basename "$script") -> linked"
done

# Install verdant theme
if [ -d "$DOTFILES/themes/verdant" ]; then
  mkdir -p ~/.config/omarchy/themes
  ln -sf "$DOTFILES/themes/verdant" ~/.config/omarchy/themes/verdant
  echo "  verdant theme -> linked"
  omarchy-theme-set verdant
  echo "  verdant theme -> applied"
fi

# Custom screensaver branding
if [ -f "$DOTFILES/branding/screensaver.txt" ]; then
  mkdir -p ~/.config/omarchy/branding
  ln -sf "$DOTFILES/branding/screensaver.txt" ~/.config/omarchy/branding/screensaver.txt
  echo "  branding/screensaver.txt -> linked"
fi

echo "Done! Hyprland will auto-reload."
