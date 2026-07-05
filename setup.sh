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
    firefox
    libimage-exiftool-perl
    vlc
    sublime-text
    git
    nodejs
    npm
    python3
    curl
    jq
    unzip
    xclip
    libxcb-xinerama0
    copyq
    btop
    inkscape
    nextcloud-desktop
    ffmpeg
    gparted
    tree
    shellcheck
    virtualbox
    docker.io
    docker-compose-v2
    gh
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
)

DEFAULT_HOMELAB_BACKUP_REPO="https://github.com/diegochagas/homelab-backup.git"
DEFAULT_HOMELAB_BACKUP_DIR="$HOME/Projects/homelab-backup"

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
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Create sublime-text.list"
    else
        echo "deb https://download.sublimetext.com/ apt/stable/" \
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

    local GIMP_SETUP_REPO_URL="${GIMP_SETUP_REPO:-https://github.com/diegochagas/gimp-setup.git}"
    local GIMP_SETUP_DIR
    GIMP_SETUP_DIR="$(mktemp -d)"

    run git clone --depth 1 "$GIMP_SETUP_REPO_URL" "$GIMP_SETUP_DIR"

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
    if [[ "$ARCHITECTURE" != "amd64" && "$ARCHITECTURE" != "arm64" ]]; then
        print_info "⏭️ Claude Desktop not supported on $ARCHITECTURE"
        SUMMARY+=("Claude Desktop|⏭️ Unsupported architecture")
        return
    fi

    #
    # Add Anthropic's APT repository
    #
    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ curl ... | sudo tee /usr/share/keyrings/claude-desktop-archive-keyring.asc"
    else
        sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
            https://downloads.claude.ai/claude-desktop/key.asc
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "➜ Create claude-desktop.list"
    else
        echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
            | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
    fi

    #
    # Install
    #
    run sudo apt update
    run sudo apt install -y claude-desktop

    SUMMARY+=("Claude Desktop|$INSTALLATION_MESSAGE")
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
    local repo_url="${HOMELAB_BACKUP_REPO:-$DEFAULT_HOMELAB_BACKUP_REPO}"
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
    run git clone "$repo_url" "$target_dir"
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

    install_claude_desktop

    configure_keyboard_shortcuts

    configure_copyq
    
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
