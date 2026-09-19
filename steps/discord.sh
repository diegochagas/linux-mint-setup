#!/usr/bin/env bash
#
# Discord, from its official Linux AMD64 .deb download.
#

: "${DISCORD_DEB_URL:=https://discord.com/api/download?platform=linux&format=deb}"

install_discord() {
    if is_apt_installed discord; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    install_deb_package discord "$DISCORD_DEB_URL"
}
