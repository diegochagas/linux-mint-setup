#!/usr/bin/env bash
#
# Spotifast, from its latest Linux release tarball, installed in the current
# user's local application directories (no root needed, unlike its .deb).
#

: "${SPOTIFAST_RELEASES_API_URL:=https://api.github.com/repos/crmne/spotifast/releases/latest}"

spotifast_release_arch() {
    case "$ARCHITECTURE" in
        amd64) echo "x86_64" ;;
        arm64) echo "aarch64" ;;
    esac
}

install_spotifast() {
    local url
    local work_dir
    local install_dir="$HOME/.local/lib/spotifast"
    local desktop_entry="$HOME/.local/share/applications/spotifast.desktop"

    ensure_user_local_bin_on_path

    if [[ -x "$HOME/.local/bin/spotifast" ]]; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    url="$(github_release_asset_url "$SPOTIFAST_RELEASES_API_URL" "$(spotifast_release_arch)-unknown-linux-gnu.tar.gz")"

    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    work_dir="$(make_work_dir spotifast)"

    download_file "$url" "$work_dir/spotifast.tar.gz"
    run mkdir -p "$install_dir"
    run tar -xzf "$work_dir/spotifast.tar.gz" -C "$install_dir" --strip-components=1
    run install -m 755 "$install_dir/spotifast" "$HOME/.local/bin/spotifast"

    if ! is_dry_run && [[ ! -r "$install_dir/packaging/icons/spotifast.svg" ]]; then
        abort "Spotifast icon was not found in the downloaded archive."
    fi

    # An absolute icon path avoids Cinnamon's generic-icon fallback when the
    # per-user hicolor theme has not yet been registered or cached.
    write_file "$desktop_entry" << EOF
[Desktop Entry]
Type=Application
Name=Spotifast
GenericName=Music Player
Comment=A fast, lightweight Spotify app
Exec=spotifast
Icon=$install_dir/packaging/icons/spotifast.svg
Terminal=false
Categories=AudioVideo;Audio;Player;
Keywords=spotify;music;streaming;
StartupWMClass=spotifast
EOF

    if binary_exists update-desktop-database; then
        run update-desktop-database "$HOME/.local/share/applications"
    fi
}
