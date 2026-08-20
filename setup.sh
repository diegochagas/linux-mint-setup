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
    # shellcheck source=/dev/null
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

APT_PACKAGES=(
    anki
    antimicrox
    btop
    copyq
    curl
    docker-compose-v2
    docker.io
    ffmpeg
    firefox
    fontconfig
    freerdp3-x11
    gh
    git
    gparted
    inkscape
    jq
    libimage-exiftool-perl
    libsecret-tools
    libxcb-xinerama0
    nextcloud-desktop
    nfs-kernel-server
    nodejs
    npm
    python3
    rsync
    shellcheck
    sublime-text
    tree
    unzip
    vlc
    xclip
    zbar-tools
)

SNAP_PACKAGES=(
    snapd
    surfshark
    code
    insomnia
    localsend
)

FLATPAK_PACKAGES=(
    com.github.dynobo.normcap
    com.google.Chrome
    xyz.riothedev.emojify
    net.code_industry.MasterPDFEditor
    org.kde.kdenlive
    org.freedownloadmanager.Manager
    io.github.diegopvlk.Dosage
    io.mgba.mGBA
    org.telegram.desktop
)

DEFAULT_GIMP_SETUP_REPO="https://github.com/diegochagas/gimp-setup.git"
DEFAULT_HOMELAB_BACKUP_REPO="https://github.com/diegochagas/homelab-backup.git"
DEFAULT_HOMELAB_BACKUP_DIR="$HOME/Projects/homelab-backup"
DEFAULT_CLAUDE_FIREFOX_REPO="https://github.com/NetVar1337/claude-for-firefox.git"
DEFAULT_SUBLIME_APT_GPG_URL="https://download.sublimetext.com/sublimehq-pub.gpg"
DEFAULT_SUBLIME_APT_REPOSITORY="deb https://download.sublimetext.com/ apt/stable/"
DEFAULT_REMOTE_MOUSE_ZIP_URL="https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip"
DEFAULT_BALENA_ETCHER_RELEASES_API_URL="https://api.github.com/repos/balena-io/etcher/releases/latest"
DEFAULT_IMMICH_GO_RELEASES_API_URL="https://api.github.com/repos/simulot/immich-go/releases/latest"
DEFAULT_APP_MANAGER_RELEASES_API_URL="https://api.github.com/repos/kem-a/AppManager/releases/latest"
DEFAULT_WATTAGE_NIGHTLY_BASE_URL="https://nightly.link/v81d/wattage/workflows/build-appimage/main"
DEFAULT_WINBOAT_APPIMAGE_URL="https://github.com/TibixDev/winboat/releases/download/v0.9.0/winboat-0.9.0-x86_64.AppImage"
DEFAULT_TAILSCALE_INSTALL_URL="https://tailscale.com/install.sh"
DEFAULT_CLAUDE_CODE_INSTALL_URL="https://claude.ai/install.sh"
DEFAULT_CLAUDE_DESKTOP_DEB_URL="https://claude.ai/api/desktop/linux/x64/deb/latest/redirect"
DEFAULT_ANTIMICROX_PROFILES_BASE_URL="https://raw.githubusercontent.com/diegochagas/linux-mint-setup/main/antimicrox/profiles"

GIMP_SETUP_REPO="${GIMP_SETUP_REPO:-$DEFAULT_GIMP_SETUP_REPO}"
HOMELAB_BACKUP_REPO="${HOMELAB_BACKUP_REPO:-$DEFAULT_HOMELAB_BACKUP_REPO}"
CLAUDE_FIREFOX_REPO="${CLAUDE_FIREFOX_REPO:-$DEFAULT_CLAUDE_FIREFOX_REPO}"
SUBLIME_APT_GPG_URL="${SUBLIME_APT_GPG_URL:-$DEFAULT_SUBLIME_APT_GPG_URL}"
SUBLIME_APT_REPOSITORY="${SUBLIME_APT_REPOSITORY:-$DEFAULT_SUBLIME_APT_REPOSITORY}"
REMOTE_MOUSE_ZIP_URL="${REMOTE_MOUSE_ZIP_URL:-$DEFAULT_REMOTE_MOUSE_ZIP_URL}"
BALENA_ETCHER_RELEASES_API_URL="${BALENA_ETCHER_RELEASES_API_URL:-$DEFAULT_BALENA_ETCHER_RELEASES_API_URL}"
IMMICH_GO_RELEASES_API_URL="${IMMICH_GO_RELEASES_API_URL:-$DEFAULT_IMMICH_GO_RELEASES_API_URL}"
APP_MANAGER_RELEASES_API_URL="${APP_MANAGER_RELEASES_API_URL:-$DEFAULT_APP_MANAGER_RELEASES_API_URL}"
WATTAGE_NIGHTLY_BASE_URL="${WATTAGE_NIGHTLY_BASE_URL:-$DEFAULT_WATTAGE_NIGHTLY_BASE_URL}"
WINBOAT_APPIMAGE_URL="${WINBOAT_APPIMAGE_URL:-$DEFAULT_WINBOAT_APPIMAGE_URL}"
TAILSCALE_INSTALL_URL="${TAILSCALE_INSTALL_URL:-$DEFAULT_TAILSCALE_INSTALL_URL}"
CLAUDE_CODE_INSTALL_URL="${CLAUDE_CODE_INSTALL_URL:-$DEFAULT_CLAUDE_CODE_INSTALL_URL}"
CLAUDE_DESKTOP_DEB_URL="${CLAUDE_DESKTOP_DEB_URL:-$DEFAULT_CLAUDE_DESKTOP_DEB_URL}"
ANTIMICROX_PROFILES_BASE_URL="${ANTIMICROX_PROFILES_BASE_URL:-$DEFAULT_ANTIMICROX_PROFILES_BASE_URL}"
GBA_LIBRARY_DIR="${GBA_LIBRARY_DIR:-}"

########################################
# Runtime options
########################################

DRY_RUN=false

INSTALLATION_MESSAGE=""
CONFIGURATION_MESSAGE=""

SUMMARY=()
CLAUDE_CODE_INSTALLER_COMPLETED=false

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
    printf -v cmd '%q ' "$@"
    print_info "➜ ${cmd% }"

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
        gpg
        systemctl
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

apt_package_needs_installation() {
    local package="$1"

    if is_apt_installed "$package"; then
        return 1
    fi

    return 0
}

install_apt_packages() {
    # Fix Snap restriction
    if [[ -f /etc/apt/preferences.d/nosnap.pref ]]; then
        run sudo mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.bak
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ wget ... | gpg --dearmor | sudo tee ..."
    else
        wget -qO - "$SUBLIME_APT_GPG_URL" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Create sublime-text.list"
    else
        echo "$SUBLIME_APT_REPOSITORY" \
            | sudo tee /etc/apt/sources.list.d/sublime-text.list >/dev/null
    fi

    local changed=false

    for package in "${APT_PACKAGES[@]}"; do
        if apt_package_needs_installation "$package"; then
            changed=true
            break
        fi
    done

    if ! $changed; then
        print_info "⏭️ All APT packages already installed"
        SUMMARY+=("APT Packages|⏭️ Already installed")
        return
    fi

    run sudo apt update
    run sudo apt install -y "${APT_PACKAGES[@]}"
        
    SUMMARY+=("APT Packages|$INSTALLATION_MESSAGE")
}

docker_target_user() {
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
        printf '%s\n' "$SUDO_USER"
    else
        id -un
    fi
}

docker_group_exists() {
    getent group docker >/dev/null 2>&1
}

user_is_in_group() {
    local user="$1"
    local group="$2"
    local groups

    groups="$(id -nG "$user" 2>/dev/null || true)"

    [[ " $groups " == *" $group "* ]]
}

docker_services_enabled_and_running() {
    command_succeeds systemctl is-enabled docker.service &&
        command_succeeds systemctl is-active docker.service &&
        command_succeeds systemctl is-enabled containerd.service &&
        command_succeeds systemctl is-active containerd.service
}

configure_docker() {
    print_step "Configuring Docker"

    local target_user
    local target_group
    local target_home
    local docker_config_dir

    target_user="$(docker_target_user)"
    target_group="$(id -gn "$target_user")"
    target_home="$(getent passwd "$target_user" | cut -d: -f6)"
    docker_config_dir="$target_home/.docker"

    if docker_group_exists &&
       user_is_in_group "$target_user" docker &&
       docker_services_enabled_and_running
    then
        print_info "⏭️ Docker already configured"
        SUMMARY+=("Docker|⏭️ Already configured")
        return
    fi

    if ! docker_group_exists; then
        run sudo groupadd docker
    fi

    if ! user_is_in_group "$target_user" docker; then
        run sudo usermod -aG docker "$target_user"
        print_info "ℹ️ Log out and back in, or run 'newgrp docker', before using Docker without sudo."
    fi

    if directory_exists "$docker_config_dir"; then
        run sudo chown "$target_user:$target_group" "$docker_config_dir" -R
        run sudo chmod g+rwx "$docker_config_dir" -R
    fi

    run sudo systemctl enable --now docker.service
    run sudo systemctl enable --now containerd.service

    SUMMARY+=("Docker|$CONFIGURATION_MESSAGE")
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
        return 1
    fi

    print_step "Installing $package..."

    run sudo snap install "$package" "$@"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "✅ $package installed"
    else
        print_info "🔄 Would install $package"
    fi

    return 0
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
        return 1
    fi

    print_step "Installing $app_id..."

    run flatpak install -y flathub "$target"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "✅ $app_id installed"
    else
        print_info "🔄 Would install $app_id"
    fi

    return 0
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
        run curl -fsSL "$REMOTE_MOUSE_ZIP_URL" -o "$REMOTE_MOUSE_DIR/remotemouse.zip"
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
        ETCHER_DEB_URL="$(curl -fsSL "$BALENA_ETCHER_RELEASES_API_URL" | jq -r '.assets[] | select(.name | endswith("_amd64.deb")) | .browser_download_url' | head -n 1)"
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
        IMMICH_GO_URL="$(curl -fsSL "$IMMICH_GO_RELEASES_API_URL" | jq -r ".assets[] | select(.name == \"immich-go_Linux_${IMMICH_GO_ARCH}.tar.gz\") | .browser_download_url" | head -n 1)"
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

appimage_artifact_arch() {
    case "$ARCHITECTURE" in
        amd64) printf "x86_64" ;;
        arm64) printf "aarch64" ;;
        *) return 1 ;;
    esac
}

find_app_manager_binary() {
    if binary_exists app-manager; then
        command -v app-manager
        return 0
    fi

    if [[ -x "$HOME/.local/bin/app-manager" ]]; then
        printf "%s\n" "$HOME/.local/bin/app-manager"
        return 0
    fi

    return 1
}

install_app_manager() {
    print_step "Installing AppManager"

    ensure_user_local_bin_on_path

    if find_app_manager_binary >/dev/null; then
        print_info "⏭️ AppManager already installed"
        SUMMARY+=("AppManager|⏭️ Already installed")
        return
    fi

    local APP_MANAGER_ARCH

    if ! APP_MANAGER_ARCH="$(appimage_artifact_arch)"; then
        print_info "⏭️ AppManager is not available for $ARCHITECTURE."
        SUMMARY+=("AppManager|⏭️ Unsupported architecture")
        return
    fi

    local APP_MANAGER_URL
    APP_MANAGER_URL="$(curl -fsSL "$APP_MANAGER_RELEASES_API_URL" | jq -r --arg arch "$APP_MANAGER_ARCH" '.assets[] | select(.name | endswith("anylinux-" + $arch + ".AppImage")) | .browser_download_url' | head -n 1)"

    if [[ -z "$APP_MANAGER_URL" || "$APP_MANAGER_URL" == "null" ]]; then
        print_info "⚠️ No AppManager $APP_MANAGER_ARCH AppImage release asset was found."
        SUMMARY+=("AppManager|⚠️ Release asset unavailable")
        return
    fi

    local APP_MANAGER_APPIMAGE

    if [[ "$DRY_RUN" == true ]]; then
        APP_MANAGER_APPIMAGE="/tmp/AppManager-${APP_MANAGER_ARCH}.AppImage"
    else
        APP_MANAGER_APPIMAGE="$(mktemp --suffix=.AppImage)"
    fi

    if ! run curl -fL --progress-bar "$APP_MANAGER_URL" -o "$APP_MANAGER_APPIMAGE"; then
        print_info "⚠️ Could not download AppManager."
        SUMMARY+=("AppManager|⚠️ Download failed")
        return
    fi

    run chmod +x "$APP_MANAGER_APPIMAGE"

    if ! run "$APP_MANAGER_APPIMAGE" install "$APP_MANAGER_APPIMAGE"; then
        print_info "⚠️ AppManager could not install itself from the downloaded AppImage."
        run rm -f "$APP_MANAGER_APPIMAGE"
        SUMMARY+=("AppManager|⚠️ Installation failed")
        return
    fi

    if [[ "$DRY_RUN" == false ]] && ! find_app_manager_binary >/dev/null; then
        print_info "⚠️ AppManager installed, but the app-manager CLI was not found."
        SUMMARY+=("AppManager|⚠️ CLI not found")
        return
    fi

    SUMMARY+=("AppManager|$INSTALLATION_MESSAGE")
}

wattage_is_installed() {
    local registry_file="$HOME/.local/share/app-manager/installations.json"

    if [[ -f "$registry_file" ]] &&
       jq -e '.installations[]? | select(((.name // "") | ascii_downcase) == "wattage" or ((.original_name // "") | ascii_downcase) == "wattage")' "$registry_file" >/dev/null 2>&1
    then
        return 0
    fi

    if binary_exists wattage || binary_exists Wattage; then
        return 0
    fi

    if compgen -G "$HOME/.local/share/applications/*Wattage*.desktop" >/dev/null; then
        return 0
    fi

    if compgen -G "$HOME/Applications/*Wattage*.AppImage" >/dev/null; then
        return 0
    fi

    return 1
}

install_wattage() {
    print_step "Installing Wattage"

    if wattage_is_installed; then
        print_info "⏭️ Wattage already installed"
        SUMMARY+=("Wattage|⏭️ Already installed")
        return
    fi

    local WATTAGE_ARCH

    if ! WATTAGE_ARCH="$(appimage_artifact_arch)"; then
        print_info "⏭️ Wattage nightly AppImage is not available for $ARCHITECTURE."
        SUMMARY+=("Wattage|⏭️ Unsupported architecture")
        return
    fi

    ensure_user_local_bin_on_path

    local APP_MANAGER_BINARY

    if [[ "$DRY_RUN" == true ]]; then
        APP_MANAGER_BINARY="$HOME/.local/bin/app-manager"
    elif ! APP_MANAGER_BINARY="$(find_app_manager_binary 2>/dev/null)"; then
        print_info "⚠️ Wattage requires AppManager, but the app-manager CLI is not available."
        SUMMARY+=("Wattage|⚠️ AppManager unavailable")
        return
    fi

    local WATTAGE_ZIP_URL="$WATTAGE_NIGHTLY_BASE_URL/Wattage-${WATTAGE_ARCH}.zip"
    local WATTAGE_DIR

    if [[ "$DRY_RUN" == true ]]; then
        WATTAGE_DIR="/tmp/wattage-appimage-${WATTAGE_ARCH}"
    else
        WATTAGE_DIR="$(mktemp -d)"
    fi

    if ! run curl -fL --progress-bar "$WATTAGE_ZIP_URL" -o "$WATTAGE_DIR/Wattage.zip"; then
        print_info "⚠️ Could not download the Wattage $WATTAGE_ARCH nightly artifact."
        run rm -rf "$WATTAGE_DIR"
        SUMMARY+=("Wattage|⚠️ Nightly artifact unavailable")
        return
    fi

    run unzip -q "$WATTAGE_DIR/Wattage.zip" -d "$WATTAGE_DIR/extracted"

    local WATTAGE_APPIMAGE

    if [[ "$DRY_RUN" == true ]]; then
        WATTAGE_APPIMAGE="$WATTAGE_DIR/extracted/Wattage-${WATTAGE_ARCH}.AppImage"
        print_info "➜ Find Wattage AppImage in $WATTAGE_DIR/extracted"
    else
        WATTAGE_APPIMAGE="$(find "$WATTAGE_DIR/extracted" -type f -iname "*.AppImage" -print -quit)"

        if [[ -z "$WATTAGE_APPIMAGE" ]]; then
            print_info "⚠️ No AppImage was found in the Wattage nightly artifact."
            run rm -rf "$WATTAGE_DIR"
            SUMMARY+=("Wattage|⚠️ AppImage not found")
            return
        fi
    fi

    run chmod +x "$WATTAGE_APPIMAGE"

    if ! run "$APP_MANAGER_BINARY" install "$WATTAGE_APPIMAGE"; then
        print_info "⚠️ AppManager could not install Wattage."
        run rm -rf "$WATTAGE_DIR"
        SUMMARY+=("Wattage|⚠️ AppManager install failed")
        return
    fi

    run rm -rf "$WATTAGE_DIR"

    SUMMARY+=("Wattage|$INSTALLATION_MESSAGE")
}

winboat_is_installed() {
    local registry_file="$HOME/.local/share/app-manager/installations.json"

    if [[ -f "$registry_file" ]] &&
       jq -e '.installations[]? | select((((.name // "") | ascii_downcase) == "winboat") or (((.original_name // "") | ascii_downcase) | contains("winboat")))' "$registry_file" >/dev/null 2>&1
    then
        return 0
    fi

    if binary_exists winboat || binary_exists WinBoat; then
        return 0
    fi

    if [[ -d "$HOME/.local/share/applications" ]] &&
       find "$HOME/.local/share/applications" -maxdepth 1 -type f -iname "*winboat*.desktop" -print -quit | grep -q .
    then
        return 0
    fi

    if [[ -d "$HOME/Applications" ]] &&
       find "$HOME/Applications" -maxdepth 1 -type f -iname "*winboat*.AppImage" -print -quit | grep -q .
    then
        return 0
    fi

    return 1
}

install_winboat() {
    print_step "Installing WinBoat"

    if winboat_is_installed; then
        print_info "⏭️ WinBoat already installed"
        SUMMARY+=("WinBoat|⏭️ Already installed")
        return
    fi

    if [[ "$ARCHITECTURE" != "amd64" ]]; then
        print_info "⏭️ WinBoat AppImage is not available for $ARCHITECTURE."
        SUMMARY+=("WinBoat|⏭️ Unsupported architecture")
        return
    fi

    ensure_user_local_bin_on_path

    local APP_MANAGER_BINARY

    if [[ "$DRY_RUN" == true ]]; then
        APP_MANAGER_BINARY="$HOME/.local/bin/app-manager"
    elif ! APP_MANAGER_BINARY="$(find_app_manager_binary 2>/dev/null)"; then
        print_info "⚠️ WinBoat requires AppManager, but the app-manager CLI is not available."
        SUMMARY+=("WinBoat|⚠️ AppManager unavailable")
        return
    fi

    local WINBOAT_APPIMAGE

    if [[ "$DRY_RUN" == true ]]; then
        WINBOAT_APPIMAGE="/tmp/winboat-x86_64.AppImage"
    else
        WINBOAT_APPIMAGE="$(mktemp --suffix=.AppImage)"
    fi

    if ! run curl -fL --progress-bar "$WINBOAT_APPIMAGE_URL" -o "$WINBOAT_APPIMAGE"; then
        print_info "⚠️ Could not download WinBoat."
        run rm -f "$WINBOAT_APPIMAGE"
        SUMMARY+=("WinBoat|⚠️ Download failed")
        return
    fi

    run chmod +x "$WINBOAT_APPIMAGE"

    if ! run "$APP_MANAGER_BINARY" install "$WINBOAT_APPIMAGE"; then
        print_info "⚠️ AppManager could not install WinBoat."
        run rm -f "$WINBOAT_APPIMAGE"
        SUMMARY+=("WinBoat|⚠️ AppManager install failed")
        return
    fi

    run rm -f "$WINBOAT_APPIMAGE"

    SUMMARY+=("WinBoat|$INSTALLATION_MESSAGE")
}

install_snap_packages() {
    local changed=false

    for package in "${SNAP_PACKAGES[@]}"; do
        if [[ "$package" == "code" ]]; then
            install_snap_package "$package" --classic && changed=true
        else
            install_snap_package "$package" && changed=true
        fi
    done

    if $changed; then
        SUMMARY+=("Snap Packages|$INSTALLATION_MESSAGE")
    else
        SUMMARY+=("Snap Packages|⏭️ Already installed")
    fi
}

install_flatpak_packages() {
    local changed=false

    for package in "${FLATPAK_PACKAGES[@]}"; do
        install_flatpak_package "$package" && changed=true
    done

    if $changed; then
        SUMMARY+=("Flatpak Packages|$INSTALLATION_MESSAGE")
    else
        SUMMARY+=("Flatpak Packages|⏭️ Already installed")
    fi
}

########################################
# Installs the complete GIMP ecosystem
# (Flatpak GIMP, plug-ins, resources and
# extra features) from the dedicated
# gimp-setup repository:
#
#   https://github.com/diegochagas/gimp-setup
#
# GIMP itself is the marker for the whole
# ecosystem: if the GIMP Flatpak is
# already installed, nothing GIMP-related
# is (re)installed. The fine-grained,
# per-feature detection lives in
# gimp-setup's own idempotent setup.sh —
# run it directly to add missing pieces
# to an existing install.
#
# The repository is cloned to a temporary
# directory and its own setup.sh does the
# work. Configuration values (the API
# keys) are forwarded through the
# environment.
########################################
install_gimp_ecosystem() {
    print_step "Installing GIMP ecosystem"

    if is_flatpak_installed org.gimp.GIMP; then
        print_info "⏭️ GIMP already installed — skipping the GIMP ecosystem"
        SUMMARY+=("GIMP Ecosystem|⏭️ Already installed")
        return
    fi

    local GIMP_SETUP_DIR
    GIMP_SETUP_DIR="$(mktemp -d)"

    run git clone --depth 1 "$GIMP_SETUP_REPO" "$GIMP_SETUP_DIR"

    local GIMP_SETUP_ARGS=()

    if [[ "$DRY_RUN" == true ]]; then
        GIMP_SETUP_ARGS+=(--dry-run)
    fi

    export GEMINI_API_KEY="${GEMINI_API_KEY:-}"
    export OPENAI_API_KEY="${OPENAI_API_KEY:-}"

    run bash "$GIMP_SETUP_DIR/setup.sh" "${GIMP_SETUP_ARGS[@]}"

    run rm -rf "$GIMP_SETUP_DIR"

    SUMMARY+=("GIMP Ecosystem|$INSTALLATION_MESSAGE")
}

install_tailscale() {
    print_step "Installing Tailscale"

    if binary_exists tailscale; then
        print_info "⏭️ Tailscale already installed"
        SUMMARY+=("Tailscale|⏭️ Already installed")
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ curl -fsSL $TAILSCALE_INSTALL_URL | sh"
    else
        curl -fsSL "$TAILSCALE_INSTALL_URL" | sh
    fi
    SUMMARY+=("Tailscale|$INSTALLATION_MESSAGE")
}

find_claude_code_binary() {
    if binary_exists claude; then
        command -v claude
        return 0
    fi

    if [[ -x "$HOME/.local/bin/claude" ]]; then
        printf '%s\n' "$HOME/.local/bin/claude"
        return 0
    fi

    local versions_dir="$HOME/.local/share/claude/versions"

    if [[ -d "$versions_dir" ]]; then
        local latest
        latest="$(find "$versions_dir" -maxdepth 3 -type f -name claude -perm /111 -print 2>/dev/null | sort -V | tail -n 1 || true)"

        if [[ -n "$latest" ]]; then
            printf '%s\n' "$latest"
            return 0
        fi
    fi

    return 1
}

ensure_user_local_bin_on_path() {
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac

    local local_bin_literal="\$HOME/.local/bin"
    local path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
    local shell_file

    for shell_file in "$HOME/.bashrc" "$HOME/.profile"; do
        if [[ -f "$shell_file" ]] &&
            (grep -Fq "$local_bin_literal" "$shell_file" || grep -Fq "$HOME/.local/bin" "$shell_file"); then
            continue
        fi

        if [[ "$DRY_RUN" == true ]]; then
            print_info "➜ Add ~/.local/bin to PATH in $shell_file"
        else
            touch "$shell_file"
            {
                echo
                echo "# Added by linux-mint-setup for user-local CLI tools."
                echo "$path_line"
            } >> "$shell_file"
        fi
    done
}

install_claude_code() {
    print_step "Installing Claude Code"

    ensure_user_local_bin_on_path

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ curl -fL --progress-bar $CLAUDE_CODE_INSTALL_URL | bash"
    else
        curl -fsSL "$CLAUDE_CODE_INSTALL_URL" | bash
    fi

    CLAUDE_CODE_INSTALLER_COMPLETED=true

    ensure_user_local_bin_on_path

    if [[ "$DRY_RUN" == false ]] && ! find_claude_code_binary >/dev/null; then
        print_info "❌ Claude Code installer completed, but the claude binary was not found."
        exit 1
    fi

    SUMMARY+=("Claude Code|$INSTALLATION_MESSAGE")
}

install_claude_desktop() {
    print_step "Installing Claude Desktop"

    #
    # Already installed?
    #
    if is_apt_installed claude-desktop; then
        print_info "⏭️ Claude Desktop already installed"
        SUMMARY+=("Claude Desktop|⏭️ Already installed")
        return
    fi

    #
    # Supported architecture?
    #
    if [[ "$ARCHITECTURE" != "amd64" ]]; then
        print_info "⏭️ Claude Desktop not supported on $ARCHITECTURE"
        SUMMARY+=("Claude Desktop|⏭️ Unsupported architecture")
        return
    fi

    #
    # Install
    #
    local CLAUDE_DESKTOP_DEB
    CLAUDE_DESKTOP_DEB="$(mktemp --suffix=.deb)"

    run curl -fL "$CLAUDE_DESKTOP_DEB_URL" -o "$CLAUDE_DESKTOP_DEB"
    run sudo apt install -y "$CLAUDE_DESKTOP_DEB"
    run rm -f "$CLAUDE_DESKTOP_DEB"

    SUMMARY+=("Claude Desktop|$INSTALLATION_MESSAGE")
}

install_claude_for_firefox() {
    print_step "Installing Claude for Firefox"

    if [[ "$CLAUDE_CODE_INSTALLER_COMPLETED" != true ]]; then
        print_info "❌ Claude for Firefox requires the Claude Code installer to complete first."
        SUMMARY+=("Claude for Firefox|❌ Claude Code installer not run")
        exit 1
    fi

    local extension_manifest="$HOME/.claude/firefox/extension/manifest.json"
    local native_host_dir="$HOME/.mozilla/native-messaging-hosts"
    local browser_native_host="$native_host_dir/com.anthropic.claude_browser_extension.json"
    local code_native_host="$native_host_dir/com.anthropic.claude_code_browser_extension.json"

    if file_exists "$extension_manifest" && file_exists "$browser_native_host" && file_exists "$code_native_host"; then
        print_info "⏭️ Claude for Firefox already installed"
        SUMMARY+=("Claude for Firefox|⏭️ Already installed")
        return
    fi

    local claude_code_bin

    if ! claude_code_bin="$(find_claude_code_binary 2>/dev/null)"; then
        if [[ "$DRY_RUN" == true ]]; then
            claude_code_bin="$HOME/.local/bin/claude"
        else
            print_info "❌ Claude Code is required before installing Claude for Firefox."
            SUMMARY+=("Claude for Firefox|❌ Missing Claude Code")
            exit 1
        fi
    fi

    local CLAUDE_FIREFOX_DIR
    CLAUDE_FIREFOX_DIR="$(mktemp -d)"

    run git clone --depth 1 "$CLAUDE_FIREFOX_REPO" "$CLAUDE_FIREFOX_DIR"
    run env CLAUDE_CODE_BIN="$claude_code_bin" bash "$CLAUDE_FIREFOX_DIR/install.sh"
    run rm -rf "$CLAUDE_FIREFOX_DIR"

    SUMMARY+=("Claude for Firefox|$INSTALLATION_MESSAGE")
}

shortcut_matches() {
    local base="$1"
    local expected_name="$2"
    local expected_command="$3"
    local expected_binding="$4"

    local current_name
    local current_command
    local current_binding

    current_name="$(dconf read "$base/name" 2>/dev/null || true)"
    current_command="$(dconf read "$base/command" 2>/dev/null || true)"
    current_binding="$(dconf read "$base/binding" 2>/dev/null || true)"

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
    local shortcut_list="['custom0', 'custom1', 'custom2']"

    local current_list
    current_list="$(dconf read /org/cinnamon/desktop/keybindings/custom-list 2>/dev/null || true)"

    if values_match "$current_list" "$shortcut_list" &&
       shortcut_matches \
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
    fi

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

    run dconf write \
        /org/cinnamon/desktop/keybindings/custom-list \
        "$shortcut_list"

    SUMMARY+=("Keyboard Shortcuts|$CONFIGURATION_MESSAGE")
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

    local current_allow_unverified
    local current_refresh_schedule
    local current_auto_update_flatpaks
    local current_auto_update_spices

    current_allow_unverified="$(gsettings get com.linuxmint.install allow-unverified-flatpaks)"
    current_refresh_schedule="$(gsettings get com.linuxmint.updates refresh-schedule-enabled)"
    current_auto_update_flatpaks="$(gsettings get com.linuxmint.updates auto-update-flatpaks)"
    current_auto_update_spices="$(gsettings get com.linuxmint.updates auto-update-cinnamon-spices)"

    if values_match "$current_allow_unverified" "true" &&
       values_match "$current_refresh_schedule" "true" &&
       values_match "$current_auto_update_flatpaks" "true" &&
       values_match "$current_auto_update_spices" "true"
    then
        print_info "⏭️ Update Manager already configured"
        SUMMARY+=("Update Manager|⏭️ Already configured")
        return
    fi

    run gsettings set com.linuxmint.install allow-unverified-flatpaks true
    run gsettings set com.linuxmint.updates refresh-schedule-enabled true
    run gsettings set com.linuxmint.updates auto-update-flatpaks true
    run gsettings set com.linuxmint.updates auto-update-cinnamon-spices true

    SUMMARY+=("Update Manager|$CONFIGURATION_MESSAGE")
}

clone_homelab_backup() {
    local target_dir="$DEFAULT_HOMELAB_BACKUP_DIR"

    if directory_exists "$target_dir/.git"; then
        print_info "⏭️ homelab-backup already cloned"
        return
    fi

    if directory_exists "$target_dir"; then
        print_info "❌ homelab-backup target exists but is not a Git repository:"
        print_info "   $target_dir"
        exit 1
    fi

    run mkdir -p "$(dirname "$target_dir")"
    run git clone "$HOMELAB_BACKUP_REPO" "$target_dir"
}

homelab_backup_service_matches() {
    local service_file="$1"

    file_exists "$service_file" && cmp -s "$service_file" - << 'EOF'
[Unit]
Description=Homelab Backup

[Service]
Type=oneshot
WorkingDirectory=%h/Projects/homelab-backup
ExecStart=%h/Projects/homelab-backup/backup.sh
EOF
}

homelab_backup_timer_matches() {
    local timer_file="$1"

    file_exists "$timer_file" && cmp -s "$timer_file" - << 'EOF'
[Unit]
Description=Run Homelab Backup

[Timer]
OnCalendar=*-*-* 10:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

homelab_backup_timer_is_enabled() {
    command_succeeds systemctl --user is-enabled homelab-backup.timer &&
        command_succeeds systemctl --user is-active homelab-backup.timer
}

configure_homelab_backup() {
    print_step "Configuring Homelab Backup"

    local target_dir="$DEFAULT_HOMELAB_BACKUP_DIR"
    local systemd_user_dir="$HOME/.config/systemd/user"
    local service_file="$systemd_user_dir/homelab-backup.service"
    local timer_file="$systemd_user_dir/homelab-backup.timer"

    clone_homelab_backup

    if [[ -x "$target_dir/backup.sh" ]] &&
       homelab_backup_service_matches "$service_file" &&
       homelab_backup_timer_matches "$timer_file" &&
       homelab_backup_timer_is_enabled
    then
        print_info "⏭️ Homelab Backup already configured"
        SUMMARY+=("Homelab Backup|⏭️ Already configured")
        return
    fi

    run chmod +x "$target_dir/backup.sh"
    run mkdir -p "$systemd_user_dir"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Create homelab-backup.service"
        print_info "➜ Create homelab-backup.timer"
    else
        cat > "$service_file" << EOF
[Unit]
Description=Homelab Backup

[Service]
Type=oneshot
WorkingDirectory=%h/Projects/homelab-backup
ExecStart=%h/Projects/homelab-backup/backup.sh
EOF

        cat > "$timer_file" << EOF
[Unit]
Description=Run Homelab Backup

[Timer]
OnCalendar=*-*-* 10:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    fi

    run systemctl --user daemon-reload
    run systemctl --user enable --now homelab-backup.timer

    SUMMARY+=("Homelab Backup|$CONFIGURATION_MESSAGE")
}

ANTIMICROX_PROFILES=(
    ALendaDoHeroi.gamecontroller.amgp
    ApocalypseAcabouAPutaria.gamecontroller.amgp
    DragonBallZFighters.gamecontroller.amgp
    FallGuys.gamecontroller.amgp
    Jaspion.gamecontroller.amgp
    MegamanCollection.gamecontroller.amgp
    SegaMegaDriveEGenesisClassics.gamecontroller.amgp
)

antimicrox_profiles_match() {
    local source_dir="$1"
    local target_dir="$2"
    local profile

    for profile in "${ANTIMICROX_PROFILES[@]}"; do
        file_exists "$target_dir/$profile" || return 1

        if file_exists "$source_dir/$profile"; then
            cmp -s "$source_dir/$profile" "$target_dir/$profile" || return 1
        fi
    done
}

configure_antimicrox() {
    print_step "Configuring AntiMicroX controller profiles"

    local source_dir="$SCRIPT_DIR/antimicrox/profiles"
    local target_dir="$HOME/.config/antimicrox/profiles"
    local profile

    if antimicrox_profiles_match "$source_dir" "$target_dir"; then
        print_info "⏭️ AntiMicroX profiles already configured"
        SUMMARY+=("AntiMicroX Profiles|⏭️ Already configured")
        return
    fi

    run mkdir -p "$target_dir"

    for profile in "${ANTIMICROX_PROFILES[@]}"; do
        if file_exists "$source_dir/$profile"; then
            run cp "$source_dir/$profile" "$target_dir/$profile"
        else
            run curl -fsSL -o "$target_dir/$profile" \
                "$ANTIMICROX_PROFILES_BASE_URL/$profile"
        fi
    done

    SUMMARY+=("AntiMicroX Profiles|$CONFIGURATION_MESSAGE")
}

########################################
# mGBA (Flatpak) is pointed at the GBA
# library set by GBA_LIBRARY_DIR in
# config.sh so ROMs are opened from
# Rooms/ and save files are read and
# written in Saves/, keeping game
# progress synced across machines.
########################################
mgba_config_matches() {
    local config_file="$1"

    file_exists "$config_file" &&
        grep -Fq "savegamePath=$GBA_LIBRARY_DIR/Saves" "$config_file" &&
        grep -Fq "lastDirectory=$GBA_LIBRARY_DIR/Rooms" "$config_file"
}

configure_mgba() {
    print_step "Configuring mGBA"

    local config_dir="$HOME/.var/app/io.mgba.mGBA/config/mgba"
    local config_file="$config_dir/config.ini"

    if [[ -z "$GBA_LIBRARY_DIR" ]]; then
        print_info "⏭️ GBA_LIBRARY_DIR is not set."
        print_info "   Set it in config.sh and re-run setup.sh."
        SUMMARY+=("mGBA|⏭️ GBA_LIBRARY_DIR not set")
        return
    fi

    if ! directory_exists "$GBA_LIBRARY_DIR"; then
        print_info "⏭️ GBA library not found (not synced yet?):"
        print_info "   $GBA_LIBRARY_DIR"
        print_info "   Re-run setup.sh after the library is available."
        SUMMARY+=("mGBA|⏭️ GBA library not found")
        return
    fi

    if mgba_config_matches "$config_file"; then
        print_info "⏭️ mGBA already configured"
        SUMMARY+=("mGBA|⏭️ Already configured")
        return
    fi

    run mkdir -p "$config_dir"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Point mGBA at the GBA library in config.ini"
    elif file_exists "$config_file" && grep -q '^\[ports\.qt\]' "$config_file"; then
        sed -i '/^savegamePath=/d; /^lastDirectory=/d' "$config_file"
        sed -i "/^\[ports\.qt\]/a lastDirectory=$GBA_LIBRARY_DIR/Rooms" "$config_file"
        sed -i "/^\[ports\.qt\]/a savegamePath=$GBA_LIBRARY_DIR/Saves" "$config_file"
    else
        {
            echo "[ports.qt]"
            echo "savegamePath=$GBA_LIBRARY_DIR/Saves"
            echo "lastDirectory=$GBA_LIBRARY_DIR/Rooms"
        } >> "$config_file"
    fi

    SUMMARY+=("mGBA|$CONFIGURATION_MESSAGE")
}

fonts_match() {
    local source_dir="$1"
    local target_dir="$2"
    local font

    directory_exists "$target_dir" || return 1

    for font in "$source_dir"/*; do
        [[ -f "$font" ]] || continue
        cmp -s "$font" "$target_dir/$(basename "$font")" || return 1
    done
}

configure_fonts() {
    print_step "Configuring Fonts"

    local source_dir="$SCRIPT_DIR/fonts"
    local target_dir="$HOME/.local/share/fonts/linux-mint-setup"
    local font

    if fonts_match "$source_dir" "$target_dir"; then
        print_info "⏭️ Fonts already configured"
        SUMMARY+=("Fonts|⏭️ Already configured")
        return
    fi

    run mkdir -p "$target_dir"

    for font in "$source_dir"/*; do
        [[ -f "$font" ]] || continue
        run cp "$font" "$target_dir/$(basename "$font")"
    done

    run fc-cache -f "$target_dir"

    SUMMARY+=("Fonts|$CONFIGURATION_MESSAGE")
}

install_system() {
    install_apt_packages

    configure_docker

    install_remote_mouse

    install_balena_etcher

    install_immich_go

    install_app_manager

    install_wattage

    install_winboat

    install_snap_packages

    install_flatpak_packages

    install_gimp_ecosystem

    install_tailscale

    install_claude_code

    install_claude_desktop

    install_claude_for_firefox

    configure_keyboard_shortcuts

    configure_copyq

    configure_fonts

    configure_antimicrox

    configure_mgba

    configure_update_manager

    configure_homelab_backup

    print_section "Setup complete!"
}

main() {
    parse_arguments "$@"

    if [[ "$DRY_RUN" == true ]]; then
        INSTALLATION_MESSAGE="🔄 Would install"
        CONFIGURATION_MESSAGE="🔄 Would configure"
    else
        INSTALLATION_MESSAGE="✅ Installed"
        CONFIGURATION_MESSAGE="✅ Configured"
    fi

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
