#!/usr/bin/env bash
#
# Snap support and Snap packages.
#

# One entry per package, followed by any extra
# "snap install" options it needs.
SNAP_PACKAGES=(
    "code --classic"
    "insomnia"
)

install_snap_packages() {
    local entry
    local package
    local installed_any=false

    if ! binary_exists snap; then
        run sudo apt install -y snapd
        installed_any=true
    fi

    for entry in "${SNAP_PACKAGES[@]}"; do
        read -r -a package <<< "$entry"

        if is_snap_installed "${package[0]}"; then
            print_info "⏭️ ${package[0]} already installed"
            continue
        fi

        run sudo snap install "${package[@]}"
        installed_any=true
    done

    if [[ "$installed_any" == false ]]; then
        skip_step "Already installed"
    fi
}
