#!/usr/bin/env bash
#
# Claude Desktop, from Anthropic's latest x64 .deb
# installer. The package registers Anthropic's APT
# repository, so it updates with the system.
#

: "${CLAUDE_DESKTOP_DEB_URL:=https://claude.ai/api/desktop/linux/x64/deb/latest/redirect}"

install_claude_desktop() {
    if is_apt_installed claude-desktop; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    install_deb_package claude-desktop "$CLAUDE_DESKTOP_DEB_URL"
}
