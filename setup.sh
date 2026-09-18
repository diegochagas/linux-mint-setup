#!/usr/bin/env bash
#
# Linux Mint Setup
#
# Post-install setup for Linux Mint. The shared helpers
# live in lib/, each setup step lives in its own file
# under steps/, and run_setup_steps below lists the steps
# in execution order.
#

set -Eeuo pipefail

readonly VERSION="0.1.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

if [[ ! -d "$SCRIPT_DIR/lib" || ! -d "$SCRIPT_DIR/steps" ]]; then
    cat >&2 << EOF
❌ setup.sh needs the lib/ and steps/ directories next to it.

Download the whole repository and run the setup from there:

    curl -fsSL https://github.com/diegochagas/linux-mint-setup/archive/refs/heads/main.tar.gz | tar -xz
    cd linux-mint-setup-main
    ./setup.sh
EOF
    exit 1
fi

########################################
# Configuration
########################################

if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    # shellcheck source=config.sh.example
    source "$SCRIPT_DIR/config.sh"
fi

########################################
# Libraries and steps
########################################

# shellcheck source-path=SCRIPTDIR

source "$SCRIPT_DIR/lib/log.sh"
source "$SCRIPT_DIR/lib/exec.sh"
source "$SCRIPT_DIR/lib/step.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/preflight.sh"

source "$SCRIPT_DIR/steps/apt-packages.sh"
source "$SCRIPT_DIR/steps/docker.sh"
source "$SCRIPT_DIR/steps/remote-mouse.sh"
source "$SCRIPT_DIR/steps/balena-etcher.sh"
source "$SCRIPT_DIR/steps/immich-go.sh"
source "$SCRIPT_DIR/steps/localsend.sh"
source "$SCRIPT_DIR/steps/app-manager.sh"
source "$SCRIPT_DIR/steps/wattage.sh"
source "$SCRIPT_DIR/steps/winboat.sh"
source "$SCRIPT_DIR/steps/snap-packages.sh"
source "$SCRIPT_DIR/steps/flatpak-packages.sh"
source "$SCRIPT_DIR/steps/gimp-ecosystem.sh"
source "$SCRIPT_DIR/steps/tailscale.sh"
source "$SCRIPT_DIR/steps/claude-code.sh"
source "$SCRIPT_DIR/steps/claude-desktop.sh"
source "$SCRIPT_DIR/steps/keyboard-shortcuts.sh"
source "$SCRIPT_DIR/steps/xcompose/xcompose.sh"
source "$SCRIPT_DIR/steps/copyq.sh"
source "$SCRIPT_DIR/steps/fonts/fonts.sh"
source "$SCRIPT_DIR/steps/antimicrox/antimicrox.sh"
source "$SCRIPT_DIR/steps/easyrpg.sh"
source "$SCRIPT_DIR/steps/update-manager.sh"
source "$SCRIPT_DIR/steps/homelab-backup.sh"

trap 'handle_error $? "${BASH_SOURCE[0]}" $LINENO "$BASH_COMMAND"' ERR
trap 'cleanup_workspace' EXIT

########################################
# Command line
########################################

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
                echo "$VERSION"
                exit 0
                ;;

            *)
                echo "❌ Unknown argument: $1" >&2
                echo >&2
                echo "Run './setup.sh --help' for usage information." >&2
                exit 1
                ;;
        esac
    done
}

########################################
# Steps, in execution order
########################################

run_setup_steps() {
    run_step install   "APT Packages"        install_apt_packages
    run_step configure "Docker"              configure_docker
    run_step install   "Remote Mouse"        install_remote_mouse
    run_step install   "balenaEtcher"        install_balena_etcher
    run_step install   "immich-go"           install_immich_go
    run_step install   "LocalSend"           install_localsend
    run_step install   "AppManager"          install_app_manager
    run_step install   "Wattage"             install_wattage
    run_step install   "WinBoat"             install_winboat
    run_step install   "Snap Packages"       install_snap_packages
    run_step install   "Flatpak Packages"    install_flatpak_packages
    run_step install   "GIMP Ecosystem"      install_gimp_ecosystem
    run_step install   "Tailscale"           install_tailscale
    run_step install   "Claude Code"         install_claude_code
    run_step install   "Claude Desktop"      install_claude_desktop
    run_step configure "Keyboard Shortcuts"  configure_keyboard_shortcuts
    run_step configure "XCompose"            configure_xcompose
    run_step configure "CopyQ"               configure_copyq
    run_step configure "LocalSend Autostart" configure_localsend_autostart
    run_step configure "Fonts"               configure_fonts
    run_step configure "AntiMicroX Profiles" configure_antimicrox
    run_step configure "EasyRPG Player"      configure_easyrpg
    run_step configure "Update Manager"      configure_update_manager
    run_step configure "Homelab Backup"      configure_homelab_backup
}

########################################
# Main
########################################

main() {
    parse_arguments "$@"

    initialize_log
    initialize_workspace

    write_log_header
    print_banner

    run_preflight_checks
    run_setup_steps

    print_section "Setup complete!"
    print_summary

    write_log_footer
}

main "$@"
