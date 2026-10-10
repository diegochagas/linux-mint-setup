#!/usr/bin/env bash
#
# Discord, from its official Linux AMD64 .deb download,
# hiding to the system tray when its window is closed.
#

: "${DISCORD_DEB_URL:=https://discord.com/api/download?platform=linux&format=deb}"

DISCORD_SETTINGS="$HOME/.config/discord/settings.json"

install_discord() {
    if is_apt_installed discord; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    install_deb_package discord "$DISCORD_DEB_URL"
}

# Closing the Discord window hides it to the system tray.
configure_discord() {
    local settings

    if ! is_apt_installed discord; then
        skip_step "Discord not installed"
        return 0
    fi

    if jq -e '.MINIMIZE_TO_TRAY == true' "$DISCORD_SETTINGS" &> /dev/null; then
        skip_step "Already configured"
        return 0
    fi

    # Discord rewrites its settings when it quits.
    if pgrep -x Discord > /dev/null; then
        warn_step "Discord is running, quit it and re-run setup.sh"
        return 0
    fi

    if file_exists "$DISCORD_SETTINGS"; then
        settings="$(jq '.MINIMIZE_TO_TRAY = true' "$DISCORD_SETTINGS")"
    else
        settings="$(jq -n '{MINIMIZE_TO_TRAY: true}')"
    fi

    write_file "$DISCORD_SETTINGS" <<< "$settings"
}
