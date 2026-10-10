#!/usr/bin/env bash
#
# Birdtray: keeps Thunderbird in the system tray, with an
# unread count. Thunderbird only has a tray of its own on
# Windows. Birdtray starts at login and launches
# Thunderbird hidden; closing or minimizing the
# Thunderbird window hides it to the tray (Birdtray
# restarts it hidden), and Quit in the tray icon menu
# quits both.
#

BIRDTRAY_APP_ID="com.ulduzsoft.Birdtray"
BIRDTRAY_CONFIG="$HOME/.var/app/$BIRDTRAY_APP_ID/config/birdtray-config.json"
BIRDTRAY_UNREAD_COLOR="#1373d9"

# Prints the inbox summary files of the profile's accounts.
birdtray_inboxes() {
    local profile_dir="$1"

    find "$profile_dir/ImapMail" "$profile_dir/Mail" -mindepth 2 -maxdepth 2 \
        -iname 'inbox.msf' 2> /dev/null | sort
}

configure_birdtray() {
    local profile_dir
    local inboxes
    local current='{}'
    local config

    if ! is_flatpak_installed "$BIRDTRAY_APP_ID"; then
        skip_step "Birdtray not installed"
        return 0
    fi

    if ! profile_dir="$(thunderbird_profile_dir)" || [[ ! -d "$profile_dir" ]]; then
        skip_step "No Thunderbird profile yet, open Thunderbird once and re-run setup.sh"
        return 0
    fi

    inboxes="$(birdtray_inboxes "$profile_dir")"

    if [[ -z "$inboxes" ]]; then
        skip_step "No Thunderbird account yet, add one and re-run setup.sh"
        return 0
    fi

    if file_exists "$BIRDTRAY_CONFIG"; then
        current="$(cat "$BIRDTRAY_CONFIG")"
    fi

    # Thunderbird runs on the host, outside Birdtray's sandbox.
    config="$(jq \
        --arg profile "$profile_dir" \
        --arg color "$BIRDTRAY_UNREAD_COLOR" \
        --arg inboxes "$inboxes" '
        . + {
            "accounts": ($inboxes | split("\n") | map({path: ., color: $color})),
            "advanced/tbcmdline": ["/usr/bin/flatpak-spawn", "--host", "thunderbird"],
            "advanced/tbprocessname": "thunderbird",
            "advanced/tbwindowmatch": " Mozilla Thunderbird",
            "common/profilepath": $profile,
            "common/showunreademailcount": true,
            "common/launchthunderbird": true,
            "common/hidewhenstarted": true,
            "common/monitorthunderbirdwindow": true,
            "common/showhidethunderbird": true,
            "common/hidewhenminimized": true,
            "common/restartthunderbird": true,
            "common/hidewhenrestarted": true,
            "common/startClosedThunderbird": true,
            "common/exitthunderbirdonquit": true
        }' <<< "$current")"

    # Birdtray reformats the file when it saves it.
    if [[ "$(jq -S . <<< "$current")" == "$(jq -S . <<< "$config")" ]] \
        && autostart_entry_exists "$BIRDTRAY_APP_ID"; then
        skip_step "Already configured"
        return 0
    fi

    # Birdtray rewrites its configuration when it quits.
    if pgrep -f "bin/birdtray" > /dev/null; then
        warn_step "Birdtray is running, quit it from its tray icon and re-run setup.sh"
        return 0
    fi

    write_file "$BIRDTRAY_CONFIG" <<< "$config"

    write_autostart_entry "$BIRDTRAY_APP_ID" << EOF
[Desktop Entry]
Type=Application
Name=Birdtray
Exec=flatpak run $BIRDTRAY_APP_ID
Icon=$BIRDTRAY_APP_ID
StartupNotify=false
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
}
