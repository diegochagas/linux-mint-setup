#!/usr/bin/env bash
#
# Fonts from the fonts directory next to this step, installed
# for the current user.
#

readonly FONTS_SOURCE_DIR="${BASH_SOURCE[0]%/*}/fonts"
readonly FONTS_TARGET_DIR="$HOME/.local/share/fonts/linux-mint-setup"

configure_fonts() {
    if directory_files_match "$FONTS_SOURCE_DIR" "$FONTS_TARGET_DIR"; then
        skip_step "Already configured"
        return 0
    fi

    copy_directory_files "$FONTS_SOURCE_DIR" "$FONTS_TARGET_DIR"
    run fc-cache -f "$FONTS_TARGET_DIR"
}
