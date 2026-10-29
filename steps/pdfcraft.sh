#!/usr/bin/env bash
#
# PdfCraft, a PDF workbench, installed for the user from the
# Flatpak bundle of its latest release:
#
#   https://github.com/storytold/pdfcraft
#
# The bundle is checked against the release's SHA256SUMS.txt
# before it is installed. Flatpak fetches the runtime it needs
# from Flathub.
#
# Once installed, PdfCraft is left as it is: to update it,
# install a newer release's bundle
# (flatpak install --user pdfcraft-<version>-linux-<arch>.flatpak).
#

: "${PDFCRAFT_RELEASES_API_URL:=https://api.github.com/repos/storytold/pdfcraft/releases/latest}"

readonly PDFCRAFT_APP_ID="ai.storyteller.pdfcraft"
readonly PDFCRAFT_CHECKSUMS_ASSET="SHA256SUMS.txt"
readonly PDFCRAFT_FLATHUB_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"

# Prints the architecture name PdfCraft uses in its asset names.
pdfcraft_asset_architecture() {
    case "$ARCHITECTURE" in
        amd64) echo "x86_64" ;;
        arm64) echo "aarch64" ;;
    esac
}

# Prints the download URL of the release asset with the given name.
pdfcraft_asset_url() {
    jq -r --arg name "$2" \
        'first(.assets[]? | select(.name == $name) | .browser_download_url) // empty' <<< "$1" 2> /dev/null || true
}

install_pdfcraft() {
    local release bundle_name bundle_url checksums_url work_dir checksum

    if is_flatpak_installed "$PDFCRAFT_APP_ID"; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    release="$(curl -fsSL "$PDFCRAFT_RELEASES_API_URL" 2> /dev/null || true)"
    bundle_name="$(jq -r --arg suffix "linux-$(pdfcraft_asset_architecture).flatpak" \
        'first(.assets[]? | select(.name | startswith("pdfcraft-") and endswith($suffix)) | .name) // empty' <<< "$release" 2> /dev/null || true)"
    bundle_url="$(pdfcraft_asset_url "$release" "$bundle_name")"
    checksums_url="$(pdfcraft_asset_url "$release" "$PDFCRAFT_CHECKSUMS_ASSET")"

    if [[ -z "$bundle_name" || -z "$bundle_url" || -z "$checksums_url" ]]; then
        warn_step "No PdfCraft release with a Flatpak bundle found"
        return 0
    fi

    work_dir="$(make_work_dir pdfcraft)"
    if ! download_file "$bundle_url" "$work_dir/$bundle_name" ||
        ! download_file "$checksums_url" "$work_dir/$PDFCRAFT_CHECKSUMS_ASSET"; then
        warn_step "Could not download PdfCraft $bundle_name"
        return 0
    fi

    print_info "➜ sha256sum $work_dir/$bundle_name"
    if ! is_dry_run; then
        checksum="$(awk -v name="$bundle_name" '$2 == name || $2 == "*" name { print $1 }' "$work_dir/$PDFCRAFT_CHECKSUMS_ASSET")"
        if [[ -z "$checksum" || "$(sha256sum "$work_dir/$bundle_name" | awk '{ print $1 }')" != "$checksum" ]]; then
            warn_step "Checksum mismatch, PdfCraft not installed"
            return 0
        fi
    fi

    # the runtime PdfCraft needs comes from Flathub, which a user
    # installation can only use as its own remote
    if ! run flatpak remote-add --user --if-not-exists flathub "$PDFCRAFT_FLATHUB_REPO" ||
        ! run flatpak install --user -y --noninteractive "$work_dir/$bundle_name"; then
        warn_step "flatpak could not install PdfCraft"
    fi
}
