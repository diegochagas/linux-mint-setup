#!/usr/bin/env bash
#
# Blender, from the official portable Linux build.
#
# The apt package lags behind and the Snap is sandboxed, so the
# pinned LTS tarball is installed to /opt/blender and linked as
# /usr/local/bin/blender (used headless by the games-extractor
# render pipeline as well as from the desktop).
#

: "${BLENDER_VERSION:=4.2.3}"
: "${BLENDER_TARBALL_URL:=https://download.blender.org/release/Blender${BLENDER_VERSION%.*}/blender-${BLENDER_VERSION}-linux-x64.tar.xz}"

readonly BLENDER_INSTALL_DIR="/opt/blender"
readonly BLENDER_BINARY="/usr/local/bin/blender"
readonly BLENDER_DESKTOP_FILE="/usr/share/applications/blender.desktop"

install_blender() {
    local work_dir
    local extracted

    if binary_exists blender; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    work_dir="$(make_work_dir blender)"

    download_file "$BLENDER_TARBALL_URL" "$work_dir/blender.tar.xz"
    run mkdir -p "$work_dir/extracted"
    run tar -xJf "$work_dir/blender.tar.xz" -C "$work_dir/extracted"

    extracted="$(find_extracted_file "$work_dir/extracted" blender)"

    if [[ -z "$extracted" ]]; then
        abort "The blender binary was not found in the downloaded archive."
    fi

    run sudo rm -rf "$BLENDER_INSTALL_DIR"
    run sudo mv "$(dirname "$extracted")" "$BLENDER_INSTALL_DIR"
    run sudo ln -sf "$BLENDER_INSTALL_DIR/blender" "$BLENDER_BINARY"

    if [[ -f "$BLENDER_INSTALL_DIR/blender.desktop" ]]; then
        run sudo install -m 644 "$BLENDER_INSTALL_DIR/blender.desktop" "$BLENDER_DESKTOP_FILE"
        run sudo sed -i "s|^Exec=blender|Exec=$BLENDER_BINARY|; s|^Icon=blender|Icon=$BLENDER_INSTALL_DIR/blender.svg|" "$BLENDER_DESKTOP_FILE"
    fi
}
