#!/usr/bin/env bash
#
# Flatpak packages from Flathub.
#

FLATPAK_PACKAGES=(
    com.github.dynobo.normcap
    com.google.Chrome
    xyz.riothedev.emojify
    net.code_industry.MasterPDFEditor
    org.kde.kdenlive
    com.obsproject.Studio
    org.freedownloadmanager.Manager
    io.github.diegopvlk.Dosage
    org.easyrpg.player
    org.telegram.desktop
    com.surfshark.Surfshark
)

install_flatpak_packages() {
    local ref
    local app_id
    local installed_any=false

    for ref in "${FLATPAK_PACKAGES[@]}"; do
        app_id="${ref%%//*}"

        if is_flatpak_installed "$app_id"; then
            print_info "⏭️ $app_id already installed"
            continue
        fi

        run flatpak install -y flathub "$ref"
        installed_any=true
    done

    if [[ "$installed_any" == false ]]; then
        skip_step "Already installed"
    fi
}
