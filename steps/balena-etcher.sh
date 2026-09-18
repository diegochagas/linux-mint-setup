#!/usr/bin/env bash
#
# balenaEtcher, from its latest AMD64 .deb release.
#

: "${BALENA_ETCHER_RELEASES_API_URL:=https://api.github.com/repos/balena-io/etcher/releases/latest}"

install_balena_etcher() {
    local url

    if binary_exists balena-etcher; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    url="$(github_release_asset_url "$BALENA_ETCHER_RELEASES_API_URL" "_amd64.deb")"

    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    install_deb_package balena-etcher "$url"
}
