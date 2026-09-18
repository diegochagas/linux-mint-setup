#!/usr/bin/env bash
#
# AntiMicroX controller profiles, copied from the
# profiles directory next to this step. Open
# AntiMicroX, click Load and pick the game's profile.
#

readonly ANTIMICROX_PROFILES_SOURCE_DIR="${BASH_SOURCE[0]%/*}/profiles"
readonly ANTIMICROX_PROFILES_TARGET_DIR="$HOME/.config/antimicrox/profiles"

configure_antimicrox() {
    if directory_files_match "$ANTIMICROX_PROFILES_SOURCE_DIR" "$ANTIMICROX_PROFILES_TARGET_DIR"; then
        skip_step "Already configured"
        return 0
    fi

    copy_directory_files "$ANTIMICROX_PROFILES_SOURCE_DIR" "$ANTIMICROX_PROFILES_TARGET_DIR"
}
