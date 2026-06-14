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
curl \
jq \
unzip \
xclip \
libxcb-xinerama0 \
copyq \
btop \
flameshot \
inkscape

# Remote Mouse and balenaEtcher (official AMD64 downloads)
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
REMOTE_MOUSE_DIR="$(mktemp -d)"
curl -fsSL https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip -o "$REMOTE_MOUSE_DIR/remotemouse.zip"
unzip -q "$REMOTE_MOUSE_DIR/remotemouse.zip" -d "$REMOTE_MOUSE_DIR/app"
sudo install -d /opt/remotemouse
sudo cp -a "$REMOTE_MOUSE_DIR/app/." /opt/remotemouse/
sudo ln -sf /opt/remotemouse/RemoteMouse /usr/local/bin/RemoteMouse
sudo tee /usr/share/applications/remotemouse.desktop > /dev/null << EOF
[Desktop Entry]
Type=Application
Name=Remote Mouse
Exec=RemoteMouse
Icon=input-mouse
Terminal=false
Categories=Utility;Network;
EOF
rm -rf "$REMOTE_MOUSE_DIR"

ETCHER_DEB="$(mktemp --suffix=.deb)"
ETCHER_DEB_URL="$(curl -fsSL https://api.github.com/repos/balena-io/etcher/releases/latest | jq -r '.assets[] | select(.name | endswith("_amd64.deb")) | .browser_download_url' | head -n 1)"
curl -fsSL "$ETCHER_DEB_URL" -o "$ETCHER_DEB"
sudo apt install -y "$ETCHER_DEB"
rm -f "$ETCHER_DEB"
else
echo "Skipping Remote Mouse and balenaEtcher: official Linux downloads require AMD64."
fi

# Snap packages
sudo apt install -y snapd
sudo snap install surfshark
sudo snap install franz
sudo snap install code --classic
sudo snap install insomnia
sudo snap install localsend

# Flatpak packages
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.gimp.GIMP.Plugin.GMic
flatpak install -y flathub com.github.dynobo.normcap
flatpak install -y flathub com.google.Chrome
flatpak install -y flathub xyz.riothedev.emojify
flatpak install -y flathub dev.nicx.mimick

# AI Remove Background plugin for Flatpak GIMP 3.2
AI_PLUGIN_NAME="ai-remove-background-g3"
AI_PLUGIN_TEMP_DIR="$(mktemp -d)"
AI_PLUGIN_FILE="$AI_PLUGIN_TEMP_DIR/$AI_PLUGIN_NAME/$AI_PLUGIN_NAME.py"

git clone https://github.com/galixstroyer/ai-remove-background-g3.git "$AI_PLUGIN_TEMP_DIR/$AI_PLUGIN_NAME"

flatpak run --command=bash org.gimp.GIMP -c "
python3 -m ensurepip --user 2>/dev/null || true
python3 -m pip install --user 'rembg[cpu,cli]' onnxruntime
"

AI_SITE_PACKAGES="$(flatpak run --command=bash org.gimp.GIMP -c "python3 -c 'import site; print(site.getusersitepackages())'")"
export AI_PLUGIN_FILE AI_SITE_PACKAGES

python3 <<'PYEOF'
import os
import re

plugin_file = os.environ["AI_PLUGIN_FILE"]
site_packages = os.environ["AI_SITE_PACKAGES"]

with open(plugin_file, encoding="utf-8") as file:
    content = file.read()

content = content.replace(
    'DEFAULT_PYTHON = os.path.expanduser("~/.rembg/bin/python")',
    'DEFAULT_PYTHON = "/usr/bin/python3"',
)

new_func = f'''def _run_rembg(python_exe: str, model: str, alpha_matting: bool,
               ae_value: int, in_path: str, out_path: str):
    script = (
        "import sys\\n"
        "sys.path.insert(0, {site_packages!r})\\n"
        "from rembg import remove, new_session\\n"
        "from PIL import Image\\n"
        "kwargs = {{'alpha_matting': " + str(alpha_matting) + ", 'alpha_matting_erode_size': " + str(int(ae_value)) + "}}\\n"
        "session = new_session('" + model + "')\\n"
        "inp = Image.open('" + in_path + "')\\n"
        "out = remove(inp, session=session, **kwargs)\\n"
        "out.save('" + out_path + "')\\n"
    )
    proc = subprocess.Popen(["/usr/bin/python3", "-c", script],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, shell=False)
    _, stderr = proc.communicate()
    if proc.returncode != 0:
        msg = stderr.decode("utf-8", errors="ignore").strip()
        raise RuntimeError(msg or "rembg exited with an error")
'''

content, replacements = re.subn(
    r"def _run_rembg\(.*?\n(?=def |\Z)",
    lambda _: new_func + "\n",
    content,
    flags=re.DOTALL,
)
if replacements != 1:
    raise RuntimeError(f"Expected to patch one _run_rembg function, patched {replacements}")

with open(plugin_file, "w", encoding="utf-8") as file:
    file.write(content)
PYEOF

flatpak override --user org.gimp.GIMP --filesystem=home

for AI_PLUGIN_DIR in \
"$HOME/.var/app/org.gimp.GIMP/config/GIMP/3.2/plug-ins/$AI_PLUGIN_NAME" \
"$HOME/.config/GIMP/3.2/plug-ins/$AI_PLUGIN_NAME" \
"$HOME/.config/GIMP/3.0/plug-ins/$AI_PLUGIN_NAME"
do
mkdir -p "$AI_PLUGIN_DIR"
install -m 755 "$AI_PLUGIN_FILE" "$AI_PLUGIN_DIR/$AI_PLUGIN_NAME.py"
done

rm -rf "$AI_PLUGIN_TEMP_DIR"

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
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Alt>s']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name "'CopyQ Toggle'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "'copyq toggle'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/binding "['<Alt>v']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "'NormCap'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "'/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=normcap com.github.dynobo.normcap'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Alt>t']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/name "'Emojify'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/command "'/usr/bin/flatpak run xyz.riothedev.emojify'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/binding "['<Alt>e']"

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
