#!/usr/bin/env bash
#
# GIMPhoto, GIMP with Photoshop's tools and interface,
# installed next to the official GIMP (its own app ID and
# user profile), from the Flatpak bundle of its latest
# release:
#
#   https://github.com/diegochagas/gimphoto
#
# The bundle is checked against the SHA-256 GitHub records
# for it and installed for the user; Flatpak fetches the
# GNOME runtime it needs from Flathub. Its AI tools run on
# the local ComfyUI installed by the Local AI step before
# this one, which GIMPhoto starts when it opens and stops
# when it closes.
#
# Once installed, GIMPhoto is left as it is: to update it,
# download a newer release's bundle, or uninstall it
# (flatpak uninstall --user io.github.diegochagas.GIMPhoto)
# and run the setup again.
#

: "${GIMPHOTO_RELEASES_API_URL:=https://api.github.com/repos/diegochagas/gimphoto/releases/latest}"

readonly GIMPHOTO_APP_ID="io.github.diegochagas.GIMPhoto"
readonly GIMPHOTO_BUNDLE_SUFFIX=".flatpak"
readonly GIMPHOTO_FLATHUB_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"

install_gimphoto() {
    local release url checksum bundle

    if is_flatpak_installed "$GIMPHOTO_APP_ID"; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    release="$(curl -fsSL "$GIMPHOTO_RELEASES_API_URL" 2> /dev/null || true)"
    url="$(jq -r --arg suffix "$GIMPHOTO_BUNDLE_SUFFIX" \
        'first(.assets[]? | select(.name | endswith($suffix)) | .browser_download_url) // empty' <<< "$release" 2> /dev/null || true)"
    checksum="$(jq -r --arg suffix "$GIMPHOTO_BUNDLE_SUFFIX" \
        'first(.assets[]? | select(.name | endswith($suffix)) | .digest) // empty' <<< "$release" 2> /dev/null |
        sed -n 's/^sha256://p')"

    if [[ -z "$url" || -z "$checksum" ]]; then
        warn_step "No GIMPhoto release with a Flatpak bundle found"
        return 0
    fi

    bundle="$(make_work_dir gimphoto)/GIMPhoto.flatpak"
    if ! download_file "$url" "$bundle"; then
        warn_step "Could not download $url"
        return 0
    fi

    print_info "➜ sha256sum $bundle"
    if ! is_dry_run && [[ "$(sha256sum "$bundle" | awk '{ print $1 }')" != "$checksum" ]]; then
        warn_step "Checksum mismatch, GIMPhoto not installed"
        return 0
    fi

    # the GNOME runtime GIMPhoto needs comes from Flathub, which a user
    # installation can only use as its own remote
    if ! run flatpak remote-add --user --if-not-exists flathub "$GIMPHOTO_FLATHUB_REPO" ||
        ! run flatpak install --user -y --noninteractive "$bundle"; then
        warn_step "flatpak could not install GIMPhoto"
    fi
}
