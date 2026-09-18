#!/usr/bin/env bash
#
# Scrcpy GUI: installation from its official AMD64 Debian release.
# The release bundle contains compatible scrcpy and adb binaries, so no
# separate runtime or PATH configuration is necessary.
#

: "${SCRCPY_GUI_RELEASES_API_URL:=https://api.github.com/repos/SimonAKing/scrcpy-gui/releases/latest}"

install_scrcpy_gui() {
    local url
    local checksums_url
    local directory
    local package
    local checksums
    local asset_name
    local expected_checksum
    local actual_checksum

    if is_apt_installed scrcpy-gui; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    url="$(github_release_asset_url "$SCRCPY_GUI_RELEASES_API_URL" "-linux-amd64.deb")"
    checksums_url="$(github_release_asset_url "$SCRCPY_GUI_RELEASES_API_URL" "SHA256SUMS.txt")"

    if [[ -z "$url" || -z "$checksums_url" ]]; then
        warn_step "Release package or checksum manifest unavailable"
        return 0
    fi

    directory="$(make_work_dir scrcpy-gui)"
    package="$directory/scrcpy-gui.deb"
    checksums="$directory/SHA256SUMS.txt"

    download_file "$url" "$package"
    download_file "$checksums_url" "$checksums"

    if is_dry_run; then
        run sudo apt install -y "$package"
        return 0
    fi

    asset_name="${url##*/}"
    asset_name="${asset_name%%\?*}"
    expected_checksum="$(awk -v name="$asset_name" '$2 == name { print $1 }' "$checksums")"
    actual_checksum="$(sha256sum "$package" | awk '{ print $1 }')"

    if [[ -z "$expected_checksum" || "$actual_checksum" != "$expected_checksum" ]]; then
        warn_step "Checksum verification failed"
        return 0
    fi

    run sudo apt install -y "$package"
}
