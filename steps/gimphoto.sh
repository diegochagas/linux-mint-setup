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

install_gimphoto() {
    local url checksum bundle

    if is_flatpak_installed "$GIMPHOTO_APP_ID"; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    url="$(github_release_asset_url "$GIMPHOTO_RELEASES_API_URL" "$GIMPHOTO_BUNDLE_SUFFIX")"
    checksum="$(github_release_asset_sha256 "$GIMPHOTO_RELEASES_API_URL" "$GIMPHOTO_BUNDLE_SUFFIX")"

    if [[ -z "$url" || -z "$checksum" ]]; then
        warn_step "No GIMPhoto release with a Flatpak bundle found"
        return 0
    fi

    bundle="$(make_work_dir gimphoto)/GIMPhoto.flatpak"
    download_file "$url" "$bundle"

    print_info "➜ sha256sum $bundle"
    if ! is_dry_run && [[ "$(sha256sum "$bundle" | awk '{ print $1 }')" != "$checksum" ]]; then
        warn_step "Checksum mismatch, GIMPhoto not installed"
        return 0
    fi

    run flatpak install --user -y --noninteractive "$bundle"
}
