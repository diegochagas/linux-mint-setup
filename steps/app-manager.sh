#!/usr/bin/env bash
#
# AppManager, an AppImage installer, plus the helpers the
# other AppImage steps (Wattage, WinBoat) use to install
# through it.
#

: "${APP_MANAGER_RELEASES_API_URL:=https://api.github.com/repos/kem-a/AppManager/releases/latest}"

readonly APP_MANAGER_REGISTRY="$HOME/.local/share/app-manager/installations.json"

# Architecture name used in AppImage file names.
appimage_arch() {
    case "$ARCHITECTURE" in
        amd64) echo "x86_64" ;;
        arm64) echo "aarch64" ;;
    esac
}

find_app_manager_binary() {
    if binary_exists app-manager; then
        command -v app-manager
        return 0
    fi

    if [[ -x "$HOME/.local/bin/app-manager" ]]; then
        echo "$HOME/.local/bin/app-manager"
        return 0
    fi

    return 1
}

# Prints the path of the app-manager CLI. In dry-run mode
# the path it would be installed to is printed when it is
# missing, since the AppManager step did not really run.
app_manager_cli() {
    if find_app_manager_binary; then
        return 0
    fi

    if is_dry_run; then
        echo "$HOME/.local/bin/app-manager"
        return 0
    fi

    return 1
}

# Checks whether AppManager's registry lists an app whose
# name contains the given (lowercase) term.
app_manager_has_app() {
    local term="$1"

    file_exists "$APP_MANAGER_REGISTRY" &&
        jq -e --arg term "$term" \
            '.installations[]? | select(((.name // "") + " " + (.original_name // "")) | ascii_downcase | contains($term))' \
            "$APP_MANAGER_REGISTRY" > /dev/null 2>&1
}

# Checks whether an AppImage app is installed, through
# AppManager's registry or by a binary, launcher or
# AppImage named after it.
#
# Arguments:
#   $1 - App name, lowercase
appimage_app_is_installed() {
    local name="$1"

    app_manager_has_app "$name" ||
        binary_exists "$name" ||
        has_file_matching "$HOME/.local/share/applications" "*$name*.desktop" ||
        has_file_matching "$HOME/Applications" "*$name*.AppImage"
}

install_app_manager() {
    local url
    local appimage

    ensure_user_local_bin_on_path

    if find_app_manager_binary > /dev/null; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    url="$(github_release_asset_url "$APP_MANAGER_RELEASES_API_URL" "anylinux-$(appimage_arch).AppImage")"

    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    appimage="$(make_work_dir app-manager)/AppManager.AppImage"

    if ! download_file "$url" "$appimage"; then
        warn_step "Download failed"
        return 0
    fi

    run chmod +x "$appimage"

    if ! run "$appimage" install "$appimage"; then
        warn_step "Installation failed"
        return 0
    fi

    if ! is_dry_run && ! find_app_manager_binary > /dev/null; then
        warn_step "CLI not found"
        return 0
    fi
}
