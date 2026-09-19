#!/usr/bin/env bash
#
# Package queries and installers: APT, Snap, Flatpak,
# .deb files and GitHub releases.
#

is_apt_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2> /dev/null)" == "installed" ]]
}

is_snap_installed() {
    snap list "$1" > /dev/null 2>&1
}

is_flatpak_installed() {
    flatpak info "$1" > /dev/null 2>&1
}

# Downloads an ASCII-armored GPG key and installs it, in
# binary form, in APT's trusted keyring directory.
install_apt_signing_key() {
    local url="$1"
    local target="$2"

    print_info "➜ curl -fsSL $url | gpg --dearmor | sudo tee $target"

    if is_dry_run; then
        return 0
    fi

    curl -fsSL "$url" | gpg --dearmor | sudo tee "$target" > /dev/null
}

# Prints the download URL of the first asset in a GitHub
# repository's latest release whose name ends with the
# given suffix. Prints nothing when there is none.
#
# Arguments:
#   $1 - Releases API URL (.../releases/latest)
#   $2 - Asset name suffix
github_release_asset_url() {
    local api_url="$1"
    local suffix="$2"

    curl -fsSL "$api_url" |
        jq -r --arg suffix "$suffix" \
            'first(.assets[] | select(.name | endswith($suffix)) | .browser_download_url) // empty'
}

# Prints the SHA-256 checksum GitHub records for the first
# asset in a repository's latest release whose name ends
# with the given suffix. Prints nothing when there is none.
#
# Arguments:
#   $1 - Releases API URL (.../releases/latest)
#   $2 - Asset name suffix
github_release_asset_sha256() {
    local api_url="$1"
    local suffix="$2"

    curl -fsSL "$api_url" |
        jq -r --arg suffix "$suffix" \
            'first(.assets[] | select(.name | endswith($suffix)) | .digest) // empty' |
        sed -n 's/^sha256://p'
}

# Downloads a .deb package and installs it with APT.
#
# Arguments:
#   $1 - Package name, used for the temporary file
#   $2 - Download URL
install_deb_package() {
    local name="$1"
    local url="$2"
    local package

    package="$(make_work_dir "$name")/$name.deb"

    download_file "$url" "$package"
    # Let APT's unprivileged _apt downloader read the local package instead of
    # falling back to an unsandboxed root download.
    run chmod 755 "$(dirname "$package")"
    run chmod 644 "$package"
    run sudo apt install -y "$package"
}
