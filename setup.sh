#!/bin/bash

set -e

echo "=================================================="
echo " Linux Mint Post-Install Setup Script"
echo "=================================================="

# Fix Snap restriction
if [ -f /etc/apt/preferences.d/nosnap.pref ]; then
sudo mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.bak
fi

# APT packages
sudo apt update

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update

sudo apt install -y \
firefox \
libimage-exiftool-perl \
vlc \
sublime-text \
git \
nodejs \
npm \
python3 \
copyq \
btop \
flameshot \
inkscape

# Snap packages
sudo apt install -y snapd
sudo snap install surfshark
sudo snap install gimp
sudo snap install franz
sudo snap install code --classic
sudo snap install insomnia
sudo snap install localsend

# Flatpak packages
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.dynobo.normcap
flatpak install -y flathub com.google.Chrome
flatpak install -y flathub io.github.vemonet.EmojiMart

# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# DaVinci Resolve
DAVINCI_RUN="$HOME/Downloads/DaVinci_Resolve_21.0_Linux/DaVinci_Resolve_21.0_Linux.run"
if [ -f "$DAVINCI_RUN" ]; then
sudo SKIP_PACKAGE_CHECK=1 "$DAVINCI_RUN" -i
cd /opt/resolve/libs
sudo mkdir -p oldlibs
sudo mv libglib* oldlibs/ 2>/dev/null || true
sudo mv libgio* oldlibs/ 2>/dev/null || true
sudo mv libgmodule* oldlibs/ 2>/dev/null || true
sudo mv libgobject* oldlibs/ 2>/dev/null || true
fi

# Keyboard shortcuts
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name "'Flameshot'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command "'flameshot gui'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Shift><Super>s']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name "'CopyQ Toggle'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "'copyq toggle'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/binding "['<Super>v']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "'NormCap'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "'/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=normcap com.github.dynobo.normcap'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Shift><Primary>s']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/name "'EmojiMart'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/command "'/usr/bin/flatpak run io.github.vemonet.EmojiMart'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/binding "['<Primary><Shift>space']"

dconf write /org/cinnamon/desktop/keybindings/custom-list "['custom0', 'custom1', 'custom2', 'custom3']"

# CopyQ autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/copyq.desktop << EOF
[Desktop Entry]
Type=Application
Name=CopyQ
Exec=copyq --start-server hide
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
# Software Manager & Update Manager preferences
gsettings set com.linuxmint.install show-unverified true 2>/dev/null || true
gsettings set com.linuxmint.updates auto-update true 2>/dev/null || true
gsettings set com.linuxmint.updates auto-refresh true 2>/dev/null || true
echo "=================================================="
echo " Setup complete!"
echo "=================================================="
