#!/usr/bin/env bash
#
# EasyRPG Player (Flatpak) is given access to the RPG
# Maker library set by RPG_MAKER_LIBRARY_DIR in config.sh:
# a directory with one subfolder per game and the shared
# RTP assets in RTP/2000 and RTP/2003. The RTP is copied
# to EasyRPG's default search path together with a GM
# soundfont for MIDI music. Games are opened with
# EasyRPG's built-in game browser and saves are written
# inside each game folder, keeping progress synced across
# machines. The library is resolved with realpath because
# the Flatpak sandbox does not follow symlinks that point
# outside the granted paths.
#

: "${RPG_MAKER_LIBRARY_DIR:=}"

readonly EASYRPG_APP_ID="org.easyrpg.player"
readonly EASYRPG_RTP_DIR="$HOME/.var/app/$EASYRPG_APP_ID/data/rtp"
readonly EASYRPG_SOUNDFONT="$EASYRPG_RTP_DIR/2000/easyrpg.soundfont"
readonly GM_SOUNDFONT="/usr/share/sounds/sf2/TimGM6mb.sf2"

easyrpg_configured() {
    local library_path="$1"

    flatpak override --user --show "$EASYRPG_APP_ID" 2> /dev/null | grep -Fq "$library_path" &&
        directory_exists "$EASYRPG_RTP_DIR/2000" &&
        directory_exists "$EASYRPG_RTP_DIR/2003" &&
        file_exists "$EASYRPG_SOUNDFONT"
}

configure_easyrpg() {
    local library_path

    if [[ -z "$RPG_MAKER_LIBRARY_DIR" ]]; then
        skip_step "RPG_MAKER_LIBRARY_DIR not set"
        print_info "   Set it in config.sh and re-run setup.sh."
        return 0
    fi

    if ! directory_exists "$RPG_MAKER_LIBRARY_DIR"; then
        skip_step "RPG Maker library not found"
        print_info "   $RPG_MAKER_LIBRARY_DIR"
        print_info "   Re-run setup.sh after the library is available (not synced yet?)."
        return 0
    fi

    library_path="$(realpath "$RPG_MAKER_LIBRARY_DIR")"

    if easyrpg_configured "$library_path"; then
        skip_step "Already configured"
        return 0
    fi

    run flatpak override --user "$EASYRPG_APP_ID" --filesystem="$library_path"
    run mkdir -p "$EASYRPG_RTP_DIR"
    run rsync -a "$RPG_MAKER_LIBRARY_DIR/RTP/" "$EASYRPG_RTP_DIR/"
    run cp "$GM_SOUNDFONT" "$EASYRPG_SOUNDFONT"
}
