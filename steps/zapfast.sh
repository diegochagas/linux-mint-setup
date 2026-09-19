#!/usr/bin/env bash
#
# ZapFast, from its latest Linux release tarball. ZapFast does not
# currently publish a Debian package, so install it in the current
# user's local application directories.
#

: "${ZAPFAST_RELEASES_API_URL:=https://api.github.com/repos/crmne/zapfast/releases/latest}"

zapfast_release_arch() {
    case "$ARCHITECTURE" in
        amd64) echo "x86_64" ;;
        arm64) echo "aarch64" ;;
    esac
}

install_zapfast() {
    local url
    local work_dir
    local install_dir="$HOME/.local/lib/zapfast"
    local desktop_entry="$HOME/.local/share/applications/zapfast.desktop"

    ensure_user_local_bin_on_path

    if [[ -x "$HOME/.local/bin/zapfast" ]]; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    url="$(github_release_asset_url "$ZAPFAST_RELEASES_API_URL" "$(zapfast_release_arch)-unknown-linux-gnu.tar.gz")"

    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    work_dir="$(make_work_dir zapfast)"

    download_file "$url" "$work_dir/zapfast.tar.gz"
    run mkdir -p "$install_dir"
    run tar -xzf "$work_dir/zapfast.tar.gz" -C "$install_dir" --strip-components=1
    run install -m 755 "$install_dir/zapfast" "$HOME/.local/bin/zapfast"

    if ! is_dry_run && [[ ! -r "$install_dir/packaging/icons/zapfast.svg" ]]; then
        abort "ZapFast icon was not found in the downloaded archive."
    fi

    # An absolute icon path avoids Cinnamon's generic-icon fallback when the
    # per-user hicolor theme has not yet been registered or cached.
    write_file "$desktop_entry" << EOF
[Desktop Entry]
Type=Application
Name=ZapFast
GenericName=WhatsApp Client
Comment=A native WhatsApp client
Exec=zapfast
Icon=$install_dir/packaging/icons/zapfast.svg
Terminal=false
Categories=Network;InstantMessaging;Chat;
Keywords=whatsapp;chat;messaging;
StartupWMClass=zapfast
EOF

    if binary_exists update-desktop-database; then
        run update-desktop-database "$HOME/.local/share/applications"
    fi
}
