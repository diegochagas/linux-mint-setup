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
inkscape \
nextcloud-desktop \
ffmpeg

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

# immich-go
case "$(dpkg --print-architecture)" in
amd64) IMMICH_GO_ARCH="x86_64" ;;
arm64) IMMICH_GO_ARCH="arm64" ;;
*) IMMICH_GO_ARCH="" ;;
esac

if [ -n "$IMMICH_GO_ARCH" ]; then
IMMICH_GO_DIR="$(mktemp -d)"
IMMICH_GO_URL="$(curl -fsSL https://api.github.com/repos/simulot/immich-go/releases/latest | jq -r ".assets[] | select(.name == \"immich-go_Linux_${IMMICH_GO_ARCH}.tar.gz\") | .browser_download_url" | head -n 1)"
if [ -z "$IMMICH_GO_URL" ]; then
echo "No immich-go Linux $IMMICH_GO_ARCH release asset was found."
exit 1
fi
curl -fsSL "$IMMICH_GO_URL" -o "$IMMICH_GO_DIR/immich-go.tar.gz"
mkdir -p "$IMMICH_GO_DIR/extracted"
tar -xzf "$IMMICH_GO_DIR/immich-go.tar.gz" -C "$IMMICH_GO_DIR/extracted"
IMMICH_GO_BINARY="$(find "$IMMICH_GO_DIR/extracted" -type f -name immich-go -print -quit)"
if [ -z "$IMMICH_GO_BINARY" ]; then
echo "immich-go binary was not found in the downloaded archive."
exit 1
fi
sudo install -m 755 "$IMMICH_GO_BINARY" /usr/local/bin/immich-go
rm -rf "$IMMICH_GO_DIR"
else
echo "Skipping immich-go: Linux $(dpkg --print-architecture) release asset is not configured."
fi

# Snap packages
sudo apt install -y snapd
sudo snap install surfshark
flatpak install -y flathub re.sonny.Tangram
sudo snap install code --classic
sudo snap install insomnia
sudo snap install localsend

# Flatpak packages
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.gimp.GIMP.Plugin.GMic
flatpak install -y flathub org.gimp.GIMP.Plugin.Resynthesizer
flatpak install -y flathub com.github.dynobo.normcap
flatpak install -y flathub com.google.Chrome
flatpak install -y flathub xyz.riothedev.emojify
flatpak install -y flathub net.codeindustry.MasterPDFEditor

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

# PhotoGIMP for Flatpak GIMP 3.x
PHOTOGIMP_CONFIG_DIR="$HOME/.config/GIMP/3.0"
PHOTOGIMP_TEMP_DIR="$(mktemp -d)"

if [ -d "$PHOTOGIMP_CONFIG_DIR" ]; then
PHOTOGIMP_BACKUP_DIR="$HOME/GIMP-3.0-backup-$(date +%Y%m%d_%H%M%S)"
cp -a "$PHOTOGIMP_CONFIG_DIR" "$PHOTOGIMP_BACKUP_DIR"
echo "Existing GIMP 3.0 configuration backed up to $PHOTOGIMP_BACKUP_DIR"
fi

curl -fsSL https://github.com/Diolinux/PhotoGIMP/releases/download/3.0/PhotoGIMP-linux.zip \
-o "$PHOTOGIMP_TEMP_DIR/PhotoGIMP-linux.zip"
unzip -q "$PHOTOGIMP_TEMP_DIR/PhotoGIMP-linux.zip" -d "$PHOTOGIMP_TEMP_DIR/photogimp"
cp -a "$PHOTOGIMP_TEMP_DIR/photogimp/." "$HOME/"
rm -rf "$PHOTOGIMP_TEMP_DIR"

# SLOS-GIMPainter brushes and presets for GIMP 3.x
SLOS_INSTALL_DIR="$HOME/.local/share/SLOS-GIMPainter"
SLOS_TEMP_DIR="$(mktemp -d)"
SLOS_GIMPRC="$HOME/.config/GIMP/3.0/gimprc"

curl -fsSL https://github.com/SenlinOS/SLOS-GIMPainter/archive/refs/heads/master.zip \
-o "$SLOS_TEMP_DIR/SLOS-GIMPainter.zip"
unzip -q "$SLOS_TEMP_DIR/SLOS-GIMPainter.zip" -d "$SLOS_TEMP_DIR"
rm -rf "$SLOS_INSTALL_DIR"
mv "$SLOS_TEMP_DIR/SLOS-GIMPainter-master" "$SLOS_INSTALL_DIR"
rm -rf "$SLOS_TEMP_DIR"

mkdir -p "$(dirname "$SLOS_GIMPRC")"
touch "$SLOS_GIMPRC"

if ! grep -Fq "$SLOS_INSTALL_DIR" "$SLOS_GIMPRC"; then
echo "(brush-path-writable \"$SLOS_INSTALL_DIR/brushes\")" >> "$SLOS_GIMPRC"
echo "(dynamics-path-writable \"$SLOS_INSTALL_DIR/dynamics\")" >> "$SLOS_GIMPRC"
echo "(tool-preset-path-writable \"$SLOS_INSTALL_DIR/tool-presets\")" >> "$SLOS_GIMPRC"
fi

# LinuxBeaver GEGL plugins for Flatpak GIMP 3.x
LINUXBEAVER_PLUGIN_DIR="$HOME/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins"
LINUXBEAVER_MANIFEST="$HOME/.local/share/LinuxBeaver-GEGL-plugins.manifest"
LINUXBEAVER_TEMP_DIR="$(mktemp -d)"

mkdir -p "$LINUXBEAVER_PLUGIN_DIR" "$(dirname "$LINUXBEAVER_MANIFEST")"

curl -fsSL https://github.com/LinuxBeaver/LinuxBeaver/releases/download/Gimp_GEGL_Plugin_download_page/LinuxBinaries_all_plugins.zip \
-o "$LINUXBEAVER_TEMP_DIR/LinuxBinaries_all_plugins.zip"
unzip -q "$LINUXBEAVER_TEMP_DIR/LinuxBinaries_all_plugins.zip" -d "$LINUXBEAVER_TEMP_DIR/extracted"

LINUXBEAVER_PLUGIN_COUNT="$(find "$LINUXBEAVER_TEMP_DIR/extracted" -maxdepth 3 -type f -name '*.so' -print | wc -l)"
if [ "$LINUXBEAVER_PLUGIN_COUNT" -eq 0 ]; then
echo "No LinuxBeaver GEGL plugin binaries were found in the downloaded archive."
exit 1
fi

if [ -f "$LINUXBEAVER_MANIFEST" ]; then
while IFS= read -r LINUXBEAVER_PLUGIN_NAME; do
case "$LINUXBEAVER_PLUGIN_NAME" in
*/*) ;;
*.so) rm -f "$LINUXBEAVER_PLUGIN_DIR/$LINUXBEAVER_PLUGIN_NAME" ;;
esac
done < "$LINUXBEAVER_MANIFEST"
fi

: > "$LINUXBEAVER_MANIFEST"
while IFS= read -r -d '' LINUXBEAVER_PLUGIN_FILE; do
LINUXBEAVER_PLUGIN_NAME="$(basename "$LINUXBEAVER_PLUGIN_FILE")"
install -m 755 "$LINUXBEAVER_PLUGIN_FILE" "$LINUXBEAVER_PLUGIN_DIR/$LINUXBEAVER_PLUGIN_NAME"
printf '%s\n' "$LINUXBEAVER_PLUGIN_NAME" >> "$LINUXBEAVER_MANIFEST"
done < <(find "$LINUXBEAVER_TEMP_DIR/extracted" -maxdepth 3 -type f -name '*.so' -print0)

rm -rf "$LINUXBEAVER_TEMP_DIR"

# GIMP AI Plugin for Flatpak GIMP 3.x (OpenAI-powered: Inpainting, Image Generator, etc.)
GIMP_AI_DETECTED_VERSION=$(flatpak run --command=bash org.gimp.GIMP -c \
    "ls ~/.config/GIMP/ 2>/dev/null" 2>/dev/null \
    | tr ' ' '\n' | sort -V -r | while IFS= read -r ver; do
        minor=$(echo "$ver" | cut -d. -f2)
        [ -n "$minor" ] && [ "$(( minor % 2 ))" -eq 0 ] && echo "$ver" && break
    done)
if [ -z "$GIMP_AI_DETECTED_VERSION" ]; then
    GIMP_AI_DETECTED_VERSION=$(flatpak run --command=bash org.gimp.GIMP -c \
        "ls ~/.config/GIMP/ 2>/dev/null" 2>/dev/null \
        | tr ' ' '\n' | sort -V | tail -1)
fi

if [ -z "$GIMP_AI_DETECTED_VERSION" ]; then
    echo "GIMP config directory not found — open GIMP once after setup, then re-run to install the GIMP AI Plugin."
else
    GIMP_AI_PLUGIN_DIR="$HOME/.config/GIMP/$GIMP_AI_DETECTED_VERSION/plug-ins/gimp-ai-plugin"
    GIMP_AI_TEMP_DIR=$(mktemp -d)
    GIMP_AI_TAG=$(curl -fsSL https://api.github.com/repos/lukaso/gimp-ai/releases/latest \
        | jq -r '.tag_name')
    GIMP_AI_ZIP_URL="https://github.com/lukaso/gimp-ai/releases/download/${GIMP_AI_TAG}/gimp-ai-plugin-${GIMP_AI_TAG}.zip"
    curl -fsSL "$GIMP_AI_ZIP_URL" -o "$GIMP_AI_TEMP_DIR/gimp-ai-plugin.zip"
    unzip -q "$GIMP_AI_TEMP_DIR/gimp-ai-plugin.zip" -d "$GIMP_AI_TEMP_DIR/extracted"
    mkdir -p "$GIMP_AI_PLUGIN_DIR"
    find "$GIMP_AI_TEMP_DIR/extracted" -name "gimp-ai-plugin.py" \
        -exec cp {} "$GIMP_AI_PLUGIN_DIR/" \;
    find "$GIMP_AI_TEMP_DIR/extracted" -name "coordinate_utils.py" \
        -exec cp {} "$GIMP_AI_PLUGIN_DIR/" \;
    chmod +x "$GIMP_AI_PLUGIN_DIR/gimp-ai-plugin.py"
    chmod +x "$GIMP_AI_PLUGIN_DIR/coordinate_utils.py"
    find "$HOME/.var/app/org.gimp.GIMP/" -name "pluginrc" -delete 2>/dev/null || true
    find "$HOME/.config/GIMP/" -name "pluginrc" -delete 2>/dev/null || true
    rm -rf "$GIMP_AI_TEMP_DIR"
fi

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
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name "'CopyQ Toggle'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command "'copyq toggle'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Alt>v']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name "'NormCap'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "'/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=normcap com.github.dynobo.normcap'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/binding "['<Alt>t']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "'Emojify'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "'/usr/bin/flatpak run xyz.riothedev.emojify'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Alt>e']"

dconf write /org/cinnamon/desktop/keybindings/custom-list "['custom0', 'custom1', 'custom2']"

# Built-in screenshot shortcuts
dconf write /org/cinnamon/desktop/keybindings/media-keys/area-screenshot-clip "['<Alt>c']"
dconf write /org/cinnamon/desktop/keybindings/media-keys/screenshot-clip "['<Shift><Super>s']"

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
