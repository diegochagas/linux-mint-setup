#!/usr/bin/env bash
#
# APT packages, including the Sublime Text repository.
#

: "${SUBLIME_APT_GPG_URL:=https://download.sublimetext.com/sublimehq-pub.gpg}"
: "${SUBLIME_APT_REPOSITORY:=deb https://download.sublimetext.com/ apt/stable/}"

readonly SUBLIME_APT_KEYRING="/etc/apt/trusted.gpg.d/sublimehq-archive.gpg"
readonly SUBLIME_APT_SOURCE="/etc/apt/sources.list.d/sublime-text.list"

# Linux Mint blocks snapd through this APT preference file.
readonly NOSNAP_PREFERENCE="/etc/apt/preferences.d/nosnap.pref"

APT_PACKAGES=(
    anki
    antimicrox
    btop
    copyq
    curl
    docker-compose-v2
    docker.io
    ffmpeg
    firefox
    fontconfig
    freerdp3-x11
    gh
    git
    gparted
    inkscape
    jq
    libimage-exiftool-perl
    libsecret-tools
    libxcb-xinerama0
    nextcloud-desktop
    nfs-kernel-server
    nodejs
    npm
    python3
    python3-yaml
    rsync
    shellcheck
    sublime-text
    timgm6mb-soundfont
    tree
    unrar
    unzip
    vlc
    xclip
    zbar-tools
)

allow_snap_packages() {
    if file_exists "$NOSNAP_PREFERENCE"; then
        run sudo mv "$NOSNAP_PREFERENCE" "${NOSNAP_PREFERENCE%.pref}.bak"
    fi
}

add_sublime_text_repository() {
    if ! file_exists "$SUBLIME_APT_KEYRING"; then
        install_apt_signing_key "$SUBLIME_APT_GPG_URL" "$SUBLIME_APT_KEYRING"
    fi

    if ! file_exists "$SUBLIME_APT_SOURCE"; then
        echo "$SUBLIME_APT_REPOSITORY" | write_root_file "$SUBLIME_APT_SOURCE"
    fi
}

# Prints the packages from APT_PACKAGES that are not installed yet.
missing_apt_packages() {
    local package

    for package in "${APT_PACKAGES[@]}"; do
        if ! is_apt_installed "$package"; then
            echo "$package"
        fi
    done
}

install_apt_packages() {
    local missing

    allow_snap_packages
    add_sublime_text_repository

    mapfile -t missing < <(missing_apt_packages)

    if (( ${#missing[@]} == 0 )); then
        skip_step "Already installed"
        return 0
    fi

    run sudo apt update
    run sudo apt install -y "${missing[@]}"
}
