#!/usr/bin/env bash
#
# LocalSend: installation from its official .deb release
# and autostart configuration.
#
# The .deb is used instead of the Snap Store build: the
# Snap is sandboxed by AppArmor, which blocks its
# NetworkManager D-Bus access (breaking the app on
# startup) and its system tray icon registration.
#

: "${LOCALSEND_RELEASES_API_URL:=https://api.github.com/repos/localsend/localsend/releases/latest}"

localsend_release_arch() {
    case "$ARCHITECTURE" in
        amd64) echo "x86-64" ;;
        arm64) echo "arm-64" ;;
    esac
}

install_localsend() {
    local url

    if is_snap_installed localsend; then
        run sudo snap remove localsend
    fi

    if is_apt_installed localsend; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    url="$(github_release_asset_url "$LOCALSEND_RELEASES_API_URL" "-linux-$(localsend_release_arch).deb")"

    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    install_deb_package localsend "$url"
}

configure_localsend_autostart() {
    if ! binary_exists localsend_app; then
        skip_step "LocalSend not installed"
        return 0
    fi

    if autostart_entry_exists localsend_app; then
        skip_step "Already configured"
        return 0
    fi

    write_autostart_entry localsend_app << 'EOF'
[Desktop Entry]
Type=Application
Name=localsend_app
Comment=localsend_app startup script
Exec=localsend_app --hidden
StartupNotify=false
Terminal=false
EOF
}
