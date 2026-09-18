#!/usr/bin/env bash
#
# Tailscale, from its official installation script.
#

: "${TAILSCALE_INSTALL_URL:=https://tailscale.com/install.sh}"

install_tailscale() {
    if binary_exists tailscale; then
        skip_step "Already installed"
        return 0
    fi

    run_remote_script "$TAILSCALE_INSTALL_URL" sh
}
