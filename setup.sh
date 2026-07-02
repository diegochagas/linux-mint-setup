#!/usr/bin/env bash

set -Eeuo pipefail
trap 'handle_error $? ${LINENO} "$BASH_COMMAND"' ERR

########################################
# Linux Mint Setup
#
# Main entry point.
########################################

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/config.sh"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

readonly VERSION="0.1.0"
START_TIME=$(date +%s)
readonly START_TIME

readonly LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H-%M-%S).log"
readonly LOG_FILE

ARCHITECTURE="$(dpkg --print-architecture)"
readonly ARCHITECTURE

########################################
# Runtime options
########################################

DRY_RUN=false

INSTALLATION_MESSAGE=""
CONFIGURATION_MESSAGE=""

SUMMARY=()

########################################
# Functions
########################################

print_info() {
    echo "$@"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$@" >> "$LOG_FILE"
    fi
}

format_time() {
    local seconds="$1"

    printf "%02d:%02d:%02d\n" \
        $((seconds/3600)) \
        $(((seconds%3600)/60)) \
        $((seconds%60))
}

print_header() {
    echo
    echo "=========================================="
    echo "        Linux Mint Setup v$VERSION"
    echo "=========================================="
    echo "Mode: $([[ "$DRY_RUN" == true ]] && echo "Simulation" || echo "Installation")"
    echo
}

if [[ "$DRY_RUN" == true ]]; then
    INSTALLATION_MESSAGE="✅ Installed"
    CONFIGURATION_MESSAGE="✅ Configured"
else
    INSTALLATION_MESSAGE="🔄 Would install"
    CONFIGURATION_MESSAGE="🔄 Would configure"
fi

########################################
# Prints a section header.
#
# Arguments:
#   $1 - Section title
########################################
print_section() {
    print_info
    print_info "========================================"
    print_info "$1"
    print_info "========================================"
    print_info
}

print_help() {
    cat << EOF
Linux Mint Setup v$VERSION

Usage:
    ./setup.sh [options]

Options:
    --dry-run           Simulate the setup.
    --help              Show help.
    --version           Show version.

Examples:
    ./setup.sh

    ./setup.sh --dry-run
EOF
}

print_version() {
    echo "$VERSION"
}

########################################
# Prints execution summary.
########################################
print_summary() {
    local elapsed="$1"

    print_section "Summary"

    for item in "${SUMMARY[@]}"; do
        IFS="|" read -r name status <<< "$item"
        print_field "$name" "$status"
    done

    print_info

    print_field "Elapsed:" "$(format_time "$elapsed")"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;

            --help)
                print_help
                exit 0
                ;;

            --version)
                print_version
                exit 0
                ;;

            *)
                print_info "❌ Unknown argument: $1"
                echo
                echo "Run './setup.sh --help' for usage information."
                exit 1
                ;;
        esac
    done
}

initialize_logging() {
    mkdir -p "$LOG_DIR"

    touch "$LOG_FILE"
}

write_log_header() {
    {
        echo "========================================"
        echo "Linux Mint Setup v$VERSION"
        echo "========================================"
        echo
        echo "Date:        $(date)"
        echo "Host:        $(hostname)"
        echo "Mode:        $([[ "$DRY_RUN" == true ]] && echo "Simulation" || echo "Installation")"
        echo
        echo "========================================"
        echo
    } >> "$LOG_FILE"
}

write_log_footer() {
    local elapsed="$1"

    {
        echo
        echo "========================================"
        echo "Finished"
        echo "========================================"
        echo
        echo "Status:      SUCCESS"
        echo "Elapsed:     $(format_time "$elapsed")"
    } >> "$LOG_FILE"
}

print_field() {
    printf "%-18s %s\n" "$1" "$2"

    if [[ -n "${LOG_FILE:-}" ]]; then
        printf "%-18s %s\n" "$1" "$2" >> "$LOG_FILE"
    fi
}

print_step() {
    print_info
    print_info "▶ $1"
    print_info
}

########################################
# Handles unexpected errors.
#
# Arguments:
#   $1 - Exit code
#   $2 - Line number
#   $3 - Command
########################################
handle_error() {
    local exit_code="$1"
    local line="$2"
    local command="$3"

    echo
    print_info "❌ Setup failed!"
    echo

    print_field "Exit code:" "$exit_code"
    print_field "Line:" "$line"
    print_field "Command:" "$command"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo
        print_info "See log:"
        print_info "  $LOG_FILE"
    fi

    exit "$exit_code"
}

########################################
# Executes a command.
#
# In dry-run mode, only prints it.
########################################
run() {
    print_info "➜ $*"

    if [[ "$DRY_RUN" == false ]]; then
        "$@"
    fi
}

########################################
# Checks whether a binary exists.
#
# Arguments:
#   $1 - Binary name
########################################
binary_exists() {
    command -v "$1" >/dev/null 2>&1
}

########################################
# Checks whether a file exists.
########################################
file_exists() {
    [[ -f "$1" ]]
}

directory_exists() {
    [[ -d "$1" ]]
}

########################################
# Checks whether a command succeeds.
#
# Arguments:
#   $@ - Command to execute
########################################
command_succeeds() {
    "$@" >/dev/null 2>&1
}

########################################
# Checks whether two values match.
#
# Arguments:
#   $1 - Current value
#   $2 - Expected value
########################################
values_match() {
    [[ "$1" == "$2" ]]
}

########################################
# Main
########################################

########################################
# Checks if required commands exist.
########################################
check_dependencies() {
    print_info "Checking dependencies..."

    local dependencies=(
        curl
        wget
        tar
        sudo
        apt
        dpkg
    )

    local missing=()

    for dependency in "${dependencies[@]}"; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            missing+=("$dependency")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        print_info "❌ Missing required dependencies:"
        for dependency in "${missing[@]}"; do
            print_info "  • $dependency"
        done

        echo
        print_info "Please install the missing dependencies and run the script again."
        exit 1
    fi

    print_info "✅ Dependencies OK"
    print_info
}

########################################
# Checks if there is an active
# internet connection.
########################################
check_internet_connection() {
    print_info "Checking internet connection..."

    if curl -Is https://github.com >/dev/null 2>&1; then
        print_info "✅ Connected"
    else
        print_info "❌ No internet connection."
        print_info
        print_info "Please connect to the internet and run the script again."
        exit 1
    fi

    print_info
}

check_sudo() {
    print_info "Checking administrator privileges..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "⏭️ Skipped (dry-run)"
        print_info
        return
    fi

    if sudo -v >/dev/null 2>&1; then
        print_info "✅ OK"
    else
        print_info "❌ Administrator privileges are required."
        exit 1
    fi

    print_info
}

check_linux_mint_version() {
    print_info "Checking operating system..."

    local os_name
    local version

    os_name=$(awk -F= '$1=="NAME" {gsub(/"/,"",$2); print $2}' /etc/os-release)
    version=$(awk -F= '$1=="VERSION_ID" {gsub(/"/,"",$2); print $2}' /etc/os-release)

    if [[ "$os_name" != "Linux Mint" ]]; then
        print_info "❌ Unsupported operating system: $os_name"
        exit 1
    fi

    print_info "✅ $os_name $version detected"
    print_info
}

initialize() {
    print_section "Initialization"

    check_dependencies

    check_sudo

    check_internet_connection

    check_linux_mint_version
}

########################################
# Package helpers
########################################

########################################
# Checks whether an APT package
# is already installed.
#
# Arguments:
#   $1 - Package name
########################################
is_apt_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

########################################
# Checks whether a Snap package
# is already installed.
#
# Arguments:
#   $1 - Package name
########################################
is_snap_installed() {
    snap list "$1" >/dev/null 2>&1
}

########################################
# Checks whether a Flatpak package
# is already installed.
#
# Arguments:
#   $1 - Flatpak ID
########################################
is_flatpak_installed() {
    flatpak info "$1" >/dev/null 2>&1
}

########################################
# Installation
########################################

install_apt_packages() {
    # Fix Snap restriction
    if [[ -f /etc/apt/preferences.d/nosnap.pref ]]; then
        run sudo mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.bak
    fi

    # APT packages
    run sudo apt update

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ wget ... | gpg --dearmor | sudo tee ..."
    else
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Create sublime-text.list"
    else
        echo "deb https://download.sublimetext.com/ apt/stable/" \
            | sudo tee /etc/apt/sources.list.d/sublime-text.list >/dev/null
    fi

    run sudo apt install -y \
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
    ffmpeg \
    gparted \
    tree \
    shellcheck \
    virtualbox
        
    SUMMARY+=("APT Packages|$INSTALLATION_MESSAGE")
}

########################################
# Installs an APT package if needed.
#
# Arguments:
#   $1 - Package name
########################################
install_apt_package() {
    local package="$1"

    if is_apt_installed "$package"; then
        print_info "⏭️  $package already installed"
        return
    fi

    print_step "Installing $package..."

    run sudo apt install -y "$package"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "🔄 Would install $package"
    else
        print_info "✅ $package installed"
    fi
}

########################################
# Installs a Snap package if needed.
#
# Arguments:
#   $1 - Package name
#   $2 - Optional extra arguments
########################################
install_snap_package() {
    local package="$1"
    shift

    if is_snap_installed "$package"; then
        print_info "⏭️  $package already installed"
        return
    fi

    print_step "Installing $package..."

    run sudo snap install "$package" "$@"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "✅ $package installed"
    else
        print_info "🔄 Would install $package"
    fi
}

########################################
# Installs a Flatpak package if needed.
#
# Arguments:
#   $1 - Flatpak ID
########################################
install_flatpak_package() {
    local target="$1"
    local app_id="${target%%//*}"

    if is_flatpak_installed "$app_id"; then
        print_info "⏭️  $app_id already installed"
        return
    fi

    print_step "Installing $app_id..."

    run flatpak install -y flathub "$target"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "✅ $app_id installed"
    else
        print_info "🔄 Would install $app_id"
    fi
}

# Remote Mouse (official AMD64 downloads)
install_remote_mouse() {
    print_step "Installing Remote Mouse"

    if binary_exists RemoteMouse; then
        print_info "⏭️ Remote Mouse already installed"
        SUMMARY+=("Remote Mouse|⏭️ Already installed")
        return
    fi

    if [[ "$ARCHITECTURE" == "amd64" ]]; then
        local REMOTE_MOUSE_DIR
        REMOTE_MOUSE_DIR="$(mktemp -d)"
        run curl -fsSL https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip -o "$REMOTE_MOUSE_DIR/remotemouse.zip"
        run unzip -q "$REMOTE_MOUSE_DIR/remotemouse.zip" -d "$REMOTE_MOUSE_DIR/app"
        run sudo install -d /opt/remotemouse
        run sudo cp -a "$REMOTE_MOUSE_DIR/app/." /opt/remotemouse/
        run sudo ln -sf /opt/remotemouse/RemoteMouse /usr/local/bin/RemoteMouse
        if [[ "$DRY_RUN" == true ]]; then
            print_info "➜ Create remotemouse.desktop"
        else
            sudo tee /usr/share/applications/remotemouse.desktop > /dev/null << EOF
[Desktop Entry]
Type=Application
Name=Remote Mouse
Exec=RemoteMouse
Icon=input-mouse
Terminal=false
Categories=Utility;Network;
EOF
        fi

        SUMMARY+=("Remote Mouse|$INSTALLATION_MESSAGE")
    else
        print_info "Skipping Remote Mouse: official Linux download requires AMD64."
    fi
}

# balenaEtcher (official AMD64 downloads)
install_balena_etcher() {
    print_step "Installing balenaEtcher"

    if binary_exists balena-etcher; then
        print_info "⏭️ balenaEtcher already installed"
        SUMMARY+=("balenaEtcher|⏭️ Already installed")
        return
    fi

    if [[ "$ARCHITECTURE" == "amd64" ]]; then
        local ETCHER_DEB
        ETCHER_DEB="$(mktemp --suffix=.deb)"
        local ETCHER_DEB_URL
        ETCHER_DEB_URL="$(curl -fsSL https://api.github.com/repos/balena-io/etcher/releases/latest | jq -r '.assets[] | select(.name | endswith("_amd64.deb")) | .browser_download_url' | head -n 1)"
        run curl -fsSL "$ETCHER_DEB_URL" -o "$ETCHER_DEB"
        run sudo apt install -y "$ETCHER_DEB"
        run rm -f "$ETCHER_DEB"
    else
        print_info "Skipping balenaEtcher: official Linux downloads require AMD64."
    fi

    SUMMARY+=("balenaEtcher|$INSTALLATION_MESSAGE")
}

install_immich_go() {
    print_step "Installing immich-go"

    if binary_exists immich-go; then
        print_info "⏭️ immich-go already installed"
        SUMMARY+=("immich-go|⏭️ Already installed")
        return
    fi

    local IMMICH_GO_ARCH=""
    
    case "$ARCHITECTURE" in
        amd64) IMMICH_GO_ARCH="x86_64" ;;
        arm64) IMMICH_GO_ARCH="arm64" ;;
        *) IMMICH_GO_ARCH="" ;;
    esac

    if [[ -n "$IMMICH_GO_ARCH" ]]; then
        local IMMICH_GO_DIR
        IMMICH_GO_DIR="$(mktemp -d)"
        local IMMICH_GO_URL
        IMMICH_GO_URL="$(curl -fsSL https://api.github.com/repos/simulot/immich-go/releases/latest | jq -r ".assets[] | select(.name == \"immich-go_Linux_${IMMICH_GO_ARCH}.tar.gz\") | .browser_download_url" | head -n 1)"
        if [[ -z "$IMMICH_GO_URL" ]]; then
            print_info "No immich-go Linux $IMMICH_GO_ARCH release asset was found."
            exit 1
        fi
        run curl -fsSL "$IMMICH_GO_URL" -o "$IMMICH_GO_DIR/immich-go.tar.gz"
        run mkdir -p "$IMMICH_GO_DIR/extracted"
        run tar -xzf "$IMMICH_GO_DIR/immich-go.tar.gz" -C "$IMMICH_GO_DIR/extracted"
        local IMMICH_GO_BINARY
        IMMICH_GO_BINARY="$(find "$IMMICH_GO_DIR/extracted" -type f -name immich-go -print -quit)"
        if [[ -z "$IMMICH_GO_BINARY" ]]; then
            print_info "immich-go binary was not found in the downloaded archive."
            exit 1
        fi
        run sudo install -m 755 "$IMMICH_GO_BINARY" /usr/local/bin/immich-go
        run rm -rf "$IMMICH_GO_DIR"
    else
        print_info "Skipping immich-go: Linux $ARCHITECTURE release asset is not configured."
    fi   
    SUMMARY+=("immich-go|$INSTALLATION_MESSAGE")  
}

install_snap_packages() {
    install_apt_package snapd

    install_snap_package surfshark
    install_snap_package code --classic
    install_snap_package insomnia
    install_snap_package localsend

    SUMMARY+=("Snap Packages|$INSTALLATION_MESSAGE")
}

install_flatpak_packages() {
    install_flatpak_package org.gimp.GIMP

    local GIMP_BRANCH="3"

    if [[ "$DRY_RUN" == false ]]; then
        GIMP_BRANCH="$(flatpak info org.gimp.GIMP --show-branch 2>/dev/null || echo "3")"
    fi

    install_flatpak_package "org.gimp.GIMP.Plugin.GMic//$GIMP_BRANCH"
    install_flatpak_package "org.gimp.GIMP.Plugin.Resynthesizer//$GIMP_BRANCH"

    install_flatpak_package com.github.dynobo.normcap
    install_flatpak_package com.google.Chrome
    install_flatpak_package xyz.riothedev.emojify
    install_flatpak_package net.codeindustry.MasterPDFEditor

    SUMMARY+=("Flatpak Packages|$INSTALLATION_MESSAGE")
}

# AI Remove Background plugin for Flatpak GIMP 3.2
install_ai_remove_background() {
    print_step "Installing AI Remove Background"

    if file_exists "$HOME/.config/GIMP/3.0/plug-ins/ai-remove-background-g3/ai-remove-background-g3.py" ||
    file_exists "$HOME/.config/GIMP/3.2/plug-ins/ai-remove-background-g3/ai-remove-background-g3.py" ||
    file_exists "$HOME/.var/app/org.gimp.GIMP/config/GIMP/3.2/plug-ins/ai-remove-background-g3/ai-remove-background-g3.py"; then
        print_info "⏭️ AI Remove Background already installed"
        SUMMARY+=("AI Remove Background|⏭️ Already installed")
        return
    fi

    local AI_PLUGIN_NAME="ai-remove-background-g3"
    local AI_PLUGIN_TEMP_DIR
    AI_PLUGIN_TEMP_DIR="$(mktemp -d)"
    local AI_PLUGIN_FILE
    AI_PLUGIN_FILE="$AI_PLUGIN_TEMP_DIR/$AI_PLUGIN_NAME/$AI_PLUGIN_NAME.py"

    run git clone https://github.com/galixstroyer/ai-remove-background-g3.git "$AI_PLUGIN_TEMP_DIR/$AI_PLUGIN_NAME"

    run flatpak run --command=bash org.gimp.GIMP -c "
    python3 -m ensurepip --user 2>/dev/null || true
    python3 -m pip install --user 'rembg[cpu,cli]' onnxruntime
    "

    local AI_SITE_PACKAGES
    AI_SITE_PACKAGES="$(flatpak run --command=bash org.gimp.GIMP -c "python3 -c 'import site; print(site.getusersitepackages())'")"
    export AI_PLUGIN_FILE AI_SITE_PACKAGES

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Patch AI Remove Background plugin"
    else
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
    fi

    run flatpak override --user org.gimp.GIMP --filesystem=home

    for AI_PLUGIN_DIR in \
        "$HOME/.var/app/org.gimp.GIMP/config/GIMP/3.2/plug-ins/$AI_PLUGIN_NAME" \
        "$HOME/.config/GIMP/3.2/plug-ins/$AI_PLUGIN_NAME" \
        "$HOME/.config/GIMP/3.0/plug-ins/$AI_PLUGIN_NAME"
    do
        run mkdir -p "$AI_PLUGIN_DIR"
        run install -m 755 "$AI_PLUGIN_FILE" "$AI_PLUGIN_DIR/$AI_PLUGIN_NAME.py"
    done

    run rm -rf "$AI_PLUGIN_TEMP_DIR"

    SUMMARY+=("AI Remove Background|$INSTALLATION_MESSAGE")
}

# PhotoGIMP for Flatpak GIMP 3.x
install_photogimp() {
    print_step "Installing PhotoGIMP"

    if file_exists "$HOME/.config/GIMP/3.0/menurc"; then
        print_info "⏭️ PhotoGIMP already installed"
        SUMMARY+=("PhotoGIMP|⏭️ Already installed")
        return
    fi
    
    local PHOTOGIMP_CONFIG_DIR="$HOME/.config/GIMP/3.0"
    local PHOTOGIMP_TEMP_DIR
    PHOTOGIMP_TEMP_DIR="$(mktemp -d)"

    if [[ -d "$PHOTOGIMP_CONFIG_DIR" ]]; then
        local PHOTOGIMP_BACKUP_DIR
        PHOTOGIMP_BACKUP_DIR="$HOME/GIMP-3.0-backup-$(date +%Y%m%d_%H%M%S)"
        run cp -a "$PHOTOGIMP_CONFIG_DIR" "$PHOTOGIMP_BACKUP_DIR"
        print_info "Existing GIMP 3.0 configuration backed up to $PHOTOGIMP_BACKUP_DIR"
    fi

    run curl -fsSL https://github.com/Diolinux/PhotoGIMP/releases/download/3.0/PhotoGIMP-linux.zip \
    -o "$PHOTOGIMP_TEMP_DIR/PhotoGIMP-linux.zip"
    run unzip -q "$PHOTOGIMP_TEMP_DIR/PhotoGIMP-linux.zip" -d "$PHOTOGIMP_TEMP_DIR/photogimp"
    run cp -a "$PHOTOGIMP_TEMP_DIR/photogimp/." "$HOME/"
    run rm -rf "$PHOTOGIMP_TEMP_DIR"

    SUMMARY+=("PhotoGIMP|$INSTALLATION_MESSAGE")
}

# SLOS-GIMPainter brushes and presets for GIMP 3.x
install_slos_gimppainter() {
    print_step "Installing SLOS-GIMPainter"

    if directory_exists "$HOME/.local/share/SLOS-GIMPainter"; then
        print_info "⏭️ SLOS-GIMPainter already installed"
        SUMMARY+=("SLOS-GIMPainter|⏭️ Already installed")
        return
    fi

    local SLOS_INSTALL_DIR="$HOME/.local/share/SLOS-GIMPainter"
    local SLOS_TEMP_DIR
    SLOS_TEMP_DIR="$(mktemp -d)"
    local SLOS_GIMPRC
    SLOS_GIMPRC="$HOME/.config/GIMP/3.0/gimprc"

    run curl -fsSL https://github.com/SenlinOS/SLOS-GIMPainter/archive/refs/heads/master.zip \
    -o "$SLOS_TEMP_DIR/SLOS-GIMPainter.zip"
    run unzip -q "$SLOS_TEMP_DIR/SLOS-GIMPainter.zip" -d "$SLOS_TEMP_DIR"
    run rm -rf "$SLOS_INSTALL_DIR"
    run mv "$SLOS_TEMP_DIR/SLOS-GIMPainter-master" "$SLOS_INSTALL_DIR"
    run rm -rf "$SLOS_TEMP_DIR"

    run mkdir -p "$(dirname "$SLOS_GIMPRC")"
    run touch "$SLOS_GIMPRC"

    if ! grep -Fq "$SLOS_INSTALL_DIR" "$SLOS_GIMPRC"; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "➜ Update $SLOS_GIMPRC"
        else
            {
                echo "(brush-path-writable \"$SLOS_INSTALL_DIR/brushes\")"
                echo "(pattern-path-writable \"$SLOS_INSTALL_DIR/patterns\")"
                echo "(gradient-path-writable \"$SLOS_INSTALL_DIR/gradients\")"
            } >> "$SLOS_GIMPRC"
        fi
    fi

    SUMMARY+=("SLOS-GIMPainter|$INSTALLATION_MESSAGE")
}

# LinuxBeaver GEGL plugins for Flatpak GIMP 3.x
install_linuxbeaver() {
    print_step "Installing LinuxBeaver GEGL Plugins"

    local LINUXBEAVER_PLUGIN_DIR="$HOME/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins"
    local LINUXBEAVER_MANIFEST="$HOME/.local/share/LinuxBeaver-GEGL-plugins.manifest"
    local LINUXBEAVER_TEMP_DIR
    LINUXBEAVER_TEMP_DIR="$(mktemp -d)"

    if file_exists "$LINUXBEAVER_MANIFEST"; then
        print_info "⏭️ LinuxBeaver already installed"
        SUMMARY+=("LinuxBeaver|⏭️ Already installed")
        return
    fi

    run mkdir -p "$LINUXBEAVER_PLUGIN_DIR" "$(dirname "$LINUXBEAVER_MANIFEST")"

    run curl -fsSL \
        "https://github.com/LinuxBeaver/LinuxBeaver/releases/download/Gimp_GEGL_Plugin_download_page/LinuxBinaries_all_plugins.zip" \
        -o "$LINUXBEAVER_TEMP_DIR/LinuxBinaries_all_plugins.zip"

    run unzip -q \
        "$LINUXBEAVER_TEMP_DIR/LinuxBinaries_all_plugins.zip" \
        -d "$LINUXBEAVER_TEMP_DIR/extracted"

    if [[ "$DRY_RUN" == false ]]; then
        local LINUXBEAVER_PLUGIN_COUNT
        LINUXBEAVER_PLUGIN_COUNT="$(find "$LINUXBEAVER_TEMP_DIR/extracted" \
            -maxdepth 3 \
            -type f \
            -name '*.so' \
            -print | wc -l)"

        if [[ "$LINUXBEAVER_PLUGIN_COUNT" -eq 0 ]]; then
            print_info "No LinuxBeaver GEGL plugin binaries were found in the downloaded archive."
            exit 1
        fi

        if [[ -f "$LINUXBEAVER_MANIFEST" ]]; then
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
        done < <(find "$LINUXBEAVER_TEMP_DIR/extracted" \
            -maxdepth 3 \
            -type f \
            -name '*.so' \
            -print0)
    fi

    run rm -rf "$LINUXBEAVER_TEMP_DIR"

    SUMMARY+=("LinuxBeaver|$INSTALLATION_MESSAGE")
}

# GIMP AI Plugin for Flatpak GIMP 3.x (OpenAI-powered: Inpainting, Image Generator, etc.)
install_gimp_ai_plugin() {
    print_step "Installing GIMP AI Plugin"

    local GIMP_AI_DETECTED_VERSION=""

    if [[ "$DRY_RUN" == false ]]; then
        GIMP_AI_DETECTED_VERSION=$(flatpak run --command=bash org.gimp.GIMP -c \
            "ls ~/.config/GIMP/ 2>/dev/null" 2>/dev/null \
            | tr ' ' '\n' | sort -V -r | while IFS= read -r ver; do
                minor=$(echo "$ver" | cut -d. -f2)
                [[ -n "$minor" ]] && (( minor % 2 == 0 )) && {
                    echo "$ver"
                    break
                }
            done)
    fi

    if file_exists "$HOME/.config/GIMP/$GIMP_AI_DETECTED_VERSION/plug-ins/gimp-ai-plugin/gimp-ai-plugin.py"; then
        print_info "⏭️ GIMP AI Plugin already installed"
        SUMMARY+=("GIMP AI Plugin|⏭️ Already installed")
        return
    fi
    
    if [[ -z "$GIMP_AI_DETECTED_VERSION" ]]; then
        GIMP_AI_DETECTED_VERSION=$(flatpak run --command=bash org.gimp.GIMP -c \
            "ls ~/.config/GIMP/ 2>/dev/null" 2>/dev/null \
            | tr ' ' '\n' | sort -V | tail -1)
    fi

    if [[ -z "$GIMP_AI_DETECTED_VERSION" ]]; then
        print_info "GIMP config directory not found — open GIMP once after setup, then re-run to install the GIMP AI Plugin."
    else
        local GIMP_AI_PLUGIN_DIR="$HOME/.config/GIMP/$GIMP_AI_DETECTED_VERSION/plug-ins/gimp-ai-plugin"
        local GIMP_AI_TEMP_DIR
        GIMP_AI_TEMP_DIR="$(mktemp -d)"
        local GIMP_AI_TAG
        GIMP_AI_TAG=$(curl -fsSL https://api.github.com/repos/lukaso/gimp-ai/releases/latest \
            | jq -r '.tag_name')
        local GIMP_AI_ZIP_URL
        GIMP_AI_ZIP_URL="https://github.com/lukaso/gimp-ai/releases/download/${GIMP_AI_TAG}/gimp-ai-plugin-${GIMP_AI_TAG}.zip"
        run curl -fsSL "$GIMP_AI_ZIP_URL" -o "$GIMP_AI_TEMP_DIR/gimp-ai-plugin.zip"
        run unzip -q "$GIMP_AI_TEMP_DIR/gimp-ai-plugin.zip" -d "$GIMP_AI_TEMP_DIR/extracted"
        run mkdir -p "$GIMP_AI_PLUGIN_DIR"
        run find "$GIMP_AI_TEMP_DIR/extracted" -name "gimp-ai-plugin.py" \
            -exec cp {} "$GIMP_AI_PLUGIN_DIR/" \;
        run find "$GIMP_AI_TEMP_DIR/extracted" -name "coordinate_utils.py" \
            -exec cp {} "$GIMP_AI_PLUGIN_DIR/" \;
        run chmod +x "$GIMP_AI_PLUGIN_DIR/gimp-ai-plugin.py"
        run chmod +x "$GIMP_AI_PLUGIN_DIR/coordinate_utils.py"
        run find "$HOME/.var/app/org.gimp.GIMP/" -name "pluginrc" -delete 2>/dev/null || true
        run find "$HOME/.config/GIMP/" -name "pluginrc" -delete
        run rm -rf "$GIMP_AI_TEMP_DIR"
    fi

    SUMMARY+=("GIMP AI Plugin|$INSTALLATION_MESSAGE")
}

install_gimp_ecosystem() {
    print_step "Installing GIMP ecosystem"

    install_ai_remove_background

    install_photogimp

    install_slos_gimppainter

    install_linuxbeaver

    install_gimp_ai_plugin
}

install_tailscale() {
    print_step "Installing Tailscale"

    if binary_exists tailscale; then
        print_info "⏭️ Tailscale already installed"
        SUMMARY+=("Tailscale|⏭️ Already installed")
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ curl -fsSL https://tailscale.com/install.sh | sh"
    else
        curl -fsSL https://tailscale.com/install.sh | sh
    fi
    SUMMARY+=("Tailscale|$INSTALLATION_MESSAGE")
}

install_davinci() {
    print_step "Installing DaVinci Resolve"

    #
    # Already installed?
    #
    if directory_exists "/opt/resolve"; then
        print_info "⏭️ DaVinci Resolve already installed"
        SUMMARY+=("DaVinci Resolve|⏭️ Already installed")
        return
    fi

    #
    # Configured?
    #
    if [[ -z "${DAVINCI_RUN:-}" ]]; then
        print_info "⏭️ DaVinci Resolve installer not configured"
        SUMMARY+=("DaVinci Resolve|⏭️ Not configured")
        return
    fi

    #
    # Installer exists?
    #
    if ! file_exists "$DAVINCI_RUN"; then
        print_info "⏭️ DaVinci Resolve installer not found"
        print_info "   $DAVINCI_RUN"
        SUMMARY+=("DaVinci Resolve|⏭️ Installer not found")
        return
    fi

    #
    # Install
    #
    print_info "Running installer..."

    run chmod +x "$DAVINCI_RUN"
    run sudo "$DAVINCI_RUN" -i

    SUMMARY+=("DaVinci Resolve|$INSTALLATION_MESSAGE")
}

shortcut_matches() {
    local base="$1"
    local expected_name="$2"
    local expected_command="$3"
    local expected_binding="$4"

    local current_name
    local current_command
    local current_binding

    current_name=$(dconf read "$base/name")
    current_command=$(dconf read "$base/command")
    current_binding=$(dconf read "$base/binding")

    values_match "$current_name" "$expected_name" &&
    values_match "$current_command" "$expected_command" &&
    values_match "$current_binding" "$expected_binding"
}

configure_shortcut() {
    local base="$1"
    local name="$2"
    local command="$3"
    local binding="$4"

    run dconf write "$base/name" "$name"
    run dconf write "$base/command" "$command"
    run dconf write "$base/binding" "$binding"
}

configure_keyboard_shortcuts() {
    print_step "Configuring Keyboard Shortcuts"

    local base="/org/cinnamon/desktop/keybindings/custom-keybindings"

    if shortcut_matches \
        "$base/custom0" \
        "'CopyQ Toggle'" \
        "'copyq toggle'" \
        "['<Alt>v']" &&
        shortcut_matches \
            "$base/custom1" \
            "'NormCap'" \
            "'/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=normcap com.github.dynobo.normcap'" \
            "['<Alt>t']" &&
        shortcut_matches \
            "$base/custom2" \
            "'Emojify'" \
            "'/usr/bin/flatpak run xyz.riothedev.emojify'" \
            "['<Alt>e']"
    then
        print_info "⏭️ Keyboard shortcuts already configured"
        SUMMARY+=("Keyboard Shortcuts|⏭️ Already configured")
        return
    else
        configure_shortcut \
            "$base/custom0" \
            "'CopyQ Toggle'" \
            "'copyq toggle'" \
            "['<Alt>v']"

        configure_shortcut \
            "$base/custom1" \
            "'NormCap'" \
            "'/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=normcap com.github.dynobo.normcap'" \
            "['<Alt>t']"

        configure_shortcut \
            "$base/custom2" \
            "'Emojify'" \
            "'/usr/bin/flatpak run xyz.riothedev.emojify'" \
            "['<Alt>e']"

        SUMMARY+=("Keyboard Shortcuts|$CONFIGURATION_MESSAGE")
    fi
}

configure_copyq() {
    print_step "Configuring CopyQ"

    if file_exists ~/.config/autostart/copyq.desktop; then
        print_info "⏭️ CopyQ already configured"
        SUMMARY+=("CopyQ|⏭️ Already configured")
        return
    fi

    run mkdir -p ~/.config/autostart
    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Create CopyQ autostart file"
    else
        cat > ~/.config/autostart/copyq.desktop << EOF
[Desktop Entry]
Type=Application
Name=CopyQ
Exec=copyq --start-server hide
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    fi

    SUMMARY+=("CopyQ|$CONFIGURATION_MESSAGE")
}

configure_update_manager() {
    print_step "Configuring Update Manager"

    local current_show_unverified
    local current_auto_update
    local current_auto_refresh

    current_show_unverified="$(gsettings get com.linuxmint.install show-unverified 2>/dev/null || true)"
    current_auto_update="$(gsettings get com.linuxmint.updates auto-update 2>/dev/null || true)"
    current_auto_refresh="$(gsettings get com.linuxmint.updates auto-refresh 2>/dev/null || true)"

    if values_match "$current_show_unverified" "true" &&
       values_match "$current_auto_update" "true" &&
       values_match "$current_auto_refresh" "true"
    then
        print_info "⏭️ Update Manager already configured"
        SUMMARY+=("Update Manager|⏭️ Already configured")
        return
    fi

    run gsettings set com.linuxmint.install show-unverified true
    run gsettings set com.linuxmint.updates auto-update true
    run gsettings set com.linuxmint.updates auto-refresh true

    SUMMARY+=("Update Manager|$CONFIGURATION_MESSAGE")
}

install_system() {
    install_apt_packages

    install_remote_mouse

    install_balena_etcher

    install_immich_go

    install_snap_packages

    install_flatpak_packages

    install_gimp_ecosystem

    install_tailscale

    install_davinci

    configure_keyboard_shortcuts

    configure_copyq
    
    configure_update_manager

    print_section "Setup complete!"
}

main() {
    parse_arguments "$@"

    initialize_logging

    write_log_header

    print_header

    initialize

    install_system

    local end_time
    end_time=$(date +%s)

    local elapsed=$((end_time - START_TIME))

    print_summary "$elapsed"

    write_log_footer "$elapsed"
}

main "$@"

