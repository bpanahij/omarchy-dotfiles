#!/bin/bash
# Install dotfiles onto a vanilla Omarchy setup
# Usage: ./install.sh

set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES"

# Install packages
echo "Installing packages..."
yay -S --needed --noconfirm kitty slack-desktop kanata-bin

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
