#!/usr/bin/env bash
#
# immich-go, from its latest release tarball.
#

: "${IMMICH_GO_RELEASES_API_URL:=https://api.github.com/repos/simulot/immich-go/releases/latest}"

immich_go_release_arch() {
    case "$ARCHITECTURE" in
        amd64) echo "x86_64" ;;
        arm64) echo "arm64" ;;
    esac
}

install_immich_go() {
    local url
    local work_dir
    local binary

    if binary_exists immich-go; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    url="$(github_release_asset_url "$IMMICH_GO_RELEASES_API_URL" "immich-go_Linux_$(immich_go_release_arch).tar.gz")"

    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    work_dir="$(make_work_dir immich-go)"

    download_file "$url" "$work_dir/immich-go.tar.gz"
    run mkdir -p "$work_dir/extracted"
    run tar -xzf "$work_dir/immich-go.tar.gz" -C "$work_dir/extracted"

    binary="$(find_extracted_file "$work_dir/extracted" immich-go)"

    if [[ -z "$binary" ]]; then
        abort "immich-go binary was not found in the downloaded archive."
    fi

    run sudo install -m 755 "$binary" /usr/local/bin/immich-go
}
