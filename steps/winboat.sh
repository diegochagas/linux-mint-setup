#!/usr/bin/env bash
#
# WinBoat, from its AMD64 AppImage release, installed
# through AppManager.
#

: "${WINBOAT_APPIMAGE_URL:=https://github.com/TibixDev/winboat/releases/download/v0.9.0/winboat-0.9.0-x86_64.AppImage}"

install_winboat() {
    local app_manager
    local appimage

    if appimage_app_is_installed winboat; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    ensure_user_local_bin_on_path

    if ! app_manager="$(app_manager_cli)"; then
        warn_step "AppManager unavailable"
        return 0
    fi

    appimage="$(make_work_dir winboat)/WinBoat.AppImage"

    if ! download_file "$WINBOAT_APPIMAGE_URL" "$appimage"; then
        warn_step "Download failed"
        return 0
    fi

    run chmod +x "$appimage"

    if ! run "$app_manager" install "$appimage"; then
        warn_step "AppManager install failed"
        return 0
    fi
}
