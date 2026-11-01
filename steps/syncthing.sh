#!/usr/bin/env bash
#
# Syncthing: the official release under ~/.local/opt (no
# sudo, and it keeps itself up to date) with a systemd user
# service, for the music library the home server shares
# (zimaos-setup README, "Music Library Sync"). Pairing the
# server device and accepting its folder is done once per
# machine in the web UI (http://127.0.0.1:8384) or with
# `syncthing cli`, so it is not part of this step.
#

: "${SYNCTHING_RELEASES_API_URL:=https://api.github.com/repos/syncthing/syncthing/releases/latest}"

readonly SYNCTHING_OPT_DIR="$HOME/.local/opt/syncthing"
readonly SYNCTHING_USER_SERVICE="$HOME/.config/systemd/user/syncthing.service"

# Prints the download URL of the Linux tarball for this
# architecture in the latest release (the asset name carries
# the version, so it is matched by prefix and suffix).
syncthing_release_tarball_url() {
    curl -fsSL "$SYNCTHING_RELEASES_API_URL" |
        jq -r --arg prefix "syncthing-linux-$ARCHITECTURE-" \
            'first(.assets[] | select((.name | startswith($prefix)) and (.name | endswith(".tar.gz"))) | .browser_download_url) // empty'
}

# The release's sha256sum.txt.asc lists every asset; the
# tarball is checked against it before anything is unpacked.
syncthing_tarball_checksum_ok() {
    local tarball="$1"
    local sums_url="${2%/*}/sha256sum.txt.asc"

    curl -fsSL "$sums_url" | grep " $(basename "$tarball")\$" |
        (cd "$(dirname "$tarball")" && sha256sum -c --quiet -)
}

install_syncthing() {
    local url work_dir tarball

    if [[ -x "$SYNCTHING_OPT_DIR/syncthing" ]] && unit_is_enabled_and_active syncthing.service --user; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    url="$(syncthing_release_tarball_url)"
    if [[ -z "$url" ]]; then
        warn_step "Release asset unavailable"
        return 0
    fi

    work_dir="$(mktemp -d)"
    tarball="$work_dir/${url##*/}"
    run curl -fsSL -o "$tarball" "$url"
    if ! is_dry_run && ! syncthing_tarball_checksum_ok "$tarball" "$url"; then
        rm -rf "$work_dir"
        abort "Syncthing tarball checksum mismatch: $url"
    fi
    run tar -xzf "$tarball" -C "$work_dir"
    run rm -rf "$SYNCTHING_OPT_DIR"
    run mkdir -p "$HOME/.local/opt" "$HOME/.local/bin" "$(dirname "$SYNCTHING_USER_SERVICE")"
    run mv "${tarball%.tar.gz}" "$SYNCTHING_OPT_DIR"
    run ln -sf "$SYNCTHING_OPT_DIR/syncthing" "$HOME/.local/bin/syncthing"
    rm -rf "$work_dir"

    configure_syncthing_user_service
}

# The upstream unit, with ExecStart pointing at the tarball
# binary instead of /usr/bin/syncthing.
configure_syncthing_user_service() {
    if is_dry_run; then
        print_info "➜ write $SYNCTHING_USER_SERVICE and enable it"
        return 0
    fi

    sed 's|^ExecStart=.*|ExecStart=%h/.local/opt/syncthing/syncthing serve --no-browser --no-restart --logflags=0|' \
        "$SYNCTHING_OPT_DIR/etc/linux-systemd/user/syncthing.service" > "$SYNCTHING_USER_SERVICE"
    run systemctl --user daemon-reload
    run systemctl --user enable --now syncthing.service
}
