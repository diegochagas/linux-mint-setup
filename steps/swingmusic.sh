#!/usr/bin/env bash
#
# Swing Music: self-hosted music player for the local
# library (https://github.com/swingmx/swingmusic).
#
# The standalone binary from the official release goes to
# ~/.local/bin and runs as a systemd user service bound to
# localhost, so only this computer reaches it. A menu entry
# opens it in the browser. The library folders come from
# SWINGMUSIC_MUSIC_DIRS; folder watching is turned on so
# new downloads (e.g. from homelab-monitor's liked-music
# sync) appear without a manual rescan.
#
# Creating the admin account (the first account becomes
# the admin and needs a password) and the playlists stays
# a manual step; see the README.
#

: "${SWINGMUSIC_RELEASES_API_URL:=https://api.github.com/repos/swingmx/swingmusic/releases/latest}"
: "${SWINGMUSIC_PORT:=1970}"
: "${SWINGMUSIC_MUSIC_DIRS:=}"

readonly SWINGMUSIC_BIN="$HOME/.local/bin/swingmusic"
readonly SWINGMUSIC_SETTINGS="$HOME/.config/swingmusic/settings.json"
readonly SWINGMUSIC_SERVICE="$HOME/.config/systemd/user/swingmusic.service"
readonly SWINGMUSIC_LAUNCHER="$HOME/.local/share/applications/swingmusic.desktop"

swingmusic_release_suffix() {
    case "$ARCHITECTURE" in
        amd64) echo "swingmusic_linux_x86_64" ;;
        arm64) echo "swingmusic_linux_aarch64" ;;
    esac
}

swingmusic_service_unit() {
    cat << EOF
[Unit]
Description=Swing Music server (local music library)
After=network-online.target

[Service]
ExecStart=%h/.local/bin/swingmusic --host 127.0.0.1 --port $SWINGMUSIC_PORT
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
}

swingmusic_launcher_entry() {
    cat << EOF
[Desktop Entry]
Type=Application
Name=Swing Music
Comment=Play the local music library
Exec=xdg-open http://127.0.0.1:$SWINGMUSIC_PORT
Icon=audio-x-generic
Categories=AudioVideo;Audio;Player;
Terminal=false
EOF
}

# Downloads the release binary and installs it only when
# its SHA-256 matches the digest GitHub records for it.
install_swingmusic() {
    local suffix url expected work_dir

    if file_exists "$SWINGMUSIC_BIN"; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    suffix="$(swingmusic_release_suffix)"
    url="$(github_release_asset_url "$SWINGMUSIC_RELEASES_API_URL" "$suffix")"
    expected="$(github_release_asset_sha256 "$SWINGMUSIC_RELEASES_API_URL" "$suffix")"

    if [[ -z "$url" || -z "$expected" ]]; then
        warn_step "Release asset or its checksum unavailable"
        return 0
    fi

    work_dir="$(make_work_dir swingmusic)"
    download_file "$url" "$work_dir/swingmusic"
    swingmusic_install_verified "$work_dir/swingmusic" "$expected"
}

# Arguments:
#   $1 - Downloaded binary
#   $2 - Expected SHA-256
swingmusic_install_verified() {
    local binary="$1"
    local expected="$2"

    if ! is_dry_run && [[ "$(sha256sum "$binary" | cut -d' ' -f1)" != "$expected" ]]; then
        warn_step "Checksum mismatch for $binary (expected $expected)"
        return 0
    fi

    run install -D -m 755 "$binary" "$SWINGMUSIC_BIN"
}

# Prints SWINGMUSIC_MUSIC_DIRS (comma-separated) as a JSON array.
swingmusic_music_dirs_json() {
    jq -cn --arg dirs "$SWINGMUSIC_MUSIC_DIRS" \
        '$dirs | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))'
}

swingmusic_library_configured() {
    file_exists "$SWINGMUSIC_SETTINGS" &&
        jq -e --argjson dirs "$(swingmusic_music_dirs_json)" \
            '.rootDirs == $dirs and .enableWatchdog == true' "$SWINGMUSIC_SETTINGS" > /dev/null 2>&1
}

swingmusic_configured() {
    swingmusic_service_unit | file_has_content "$SWINGMUSIC_SERVICE" &&
        swingmusic_launcher_entry | file_has_content "$SWINGMUSIC_LAUNCHER" &&
        unit_is_enabled_and_active swingmusic.service --user &&
        { [[ -z "$SWINGMUSIC_MUSIC_DIRS" ]] || swingmusic_library_configured; }
}

configure_swingmusic() {
    if ! file_exists "$SWINGMUSIC_BIN" && ! is_dry_run; then
        skip_step "Swing Music not installed"
        return 0
    fi

    if swingmusic_configured; then
        skip_step "Already configured"
        return 0
    fi

    swingmusic_service_unit | write_file "$SWINGMUSIC_SERVICE"
    swingmusic_launcher_entry | write_file "$SWINGMUSIC_LAUNCHER"
    run systemctl --user daemon-reload
    run systemctl --user enable --now swingmusic.service
    swingmusic_configure_library
}

# Swing Music writes settings.json on its first start, so
# the library is set after the service has run once, and
# with the service stopped so it doesn't overwrite the change.
swingmusic_configure_library() {
    if [[ -z "$SWINGMUSIC_MUSIC_DIRS" ]]; then
        print_info "⏭️ SWINGMUSIC_MUSIC_DIRS is empty, add the library folders in Swing Music's settings"
        return 0
    fi

    if swingmusic_library_configured; then
        return 0
    fi

    if ! swingmusic_wait_for_settings; then
        warn_step "$SWINGMUSIC_SETTINGS did not appear, set the folders in Swing Music's settings"
        return 0
    fi

    swingmusic_write_library_settings
}

swingmusic_wait_for_settings() {
    local attempt

    is_dry_run && return 0

    for attempt in {1..30}; do
        file_exists "$SWINGMUSIC_SETTINGS" && return 0
        print_info "⏳ Waiting for Swing Music's first start ($attempt/30)"
        sleep 2
    done

    return 1
}

swingmusic_write_library_settings() {
    local updated

    run systemctl --user stop swingmusic.service

    if ! is_dry_run; then
        updated="$(jq --argjson dirs "$(swingmusic_music_dirs_json)" \
            '.rootDirs = $dirs | .enableWatchdog = true' "$SWINGMUSIC_SETTINGS")"
        printf '%s\n' "$updated" | write_file "$SWINGMUSIC_SETTINGS"
    fi

    run systemctl --user start swingmusic.service
}
