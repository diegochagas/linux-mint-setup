#!/usr/bin/env bash
#
# calibre, from its official Linux installer.
#
# The apt package lags several major versions behind and the
# Flatpak is sandboxed, so the installer from calibre-ebook.com
# is used. It installs to /opt/calibre, links the command-line
# tools into /usr/bin and adds the desktop entry.
#

: "${CALIBRE_INSTALLER_URL:=https://download.calibre-ebook.com/linux-installer.sh}"

install_calibre() {
    local work_dir

    if binary_exists calibre; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    work_dir="$(make_work_dir calibre)"

    download_file "$CALIBRE_INSTALLER_URL" "$work_dir/linux-installer.sh"
    run sudo sh "$work_dir/linux-installer.sh"
}
