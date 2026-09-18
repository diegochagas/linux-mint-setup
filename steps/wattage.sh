#!/usr/bin/env bash
#
# Wattage, from its nightly AppImage build, installed
# through AppManager.
#

: "${WATTAGE_NIGHTLY_BASE_URL:=https://nightly.link/v81d/wattage/workflows/build-appimage/main}"

install_wattage() {
    local app_manager
    local work_dir
    local appimage

    if appimage_app_is_installed wattage; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    ensure_user_local_bin_on_path

    if ! app_manager="$(app_manager_cli)"; then
        warn_step "AppManager unavailable"
        return 0
    fi

    work_dir="$(make_work_dir wattage)"

    if ! download_file "$WATTAGE_NIGHTLY_BASE_URL/Wattage-$(appimage_arch).zip" "$work_dir/Wattage.zip"; then
        warn_step "Nightly artifact unavailable"
        return 0
    fi

    run unzip -q "$work_dir/Wattage.zip" -d "$work_dir/extracted"

    appimage="$(find_extracted_file "$work_dir/extracted" "*.AppImage")"

    if [[ -z "$appimage" ]]; then
        warn_step "AppImage not found"
        return 0
    fi

    run chmod +x "$appimage"

    if ! run "$app_manager" install "$appimage"; then
        warn_step "AppManager install failed"
        return 0
    fi
}
