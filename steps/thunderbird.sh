#!/usr/bin/env bash
#
# Thunderbird: show the full content of every email.
#

THUNDERBIRD_DIR="$HOME/.thunderbird"

# Preferences as "name value", written to user.js so they
# are applied every time Thunderbird starts.
THUNDERBIRD_PREFS=(
    "mailnews.message_display.disable_remote_image false"
    "mailnews.display.html_as 0"
    "mailnews.display.prefer_plaintext false"
)

# Prints the path of the profile Thunderbird opens by default.
thunderbird_profile_dir() {
    local profiles_ini="$THUNDERBIRD_DIR/profiles.ini"
    local profile

    [[ -f "$profiles_ini" ]] || return 1

    profile="$(awk -F= '
        /^\[Install/ { install = 1; next }
        /^\[/        { install = 0 }
        install && $1 == "Default" { print $2; exit }
    ' "$profiles_ini")"

    if [[ -z "$profile" ]]; then
        profile="$(awk -F= '
            /^\[/ { path = ""; is_default = 0 }
            $1 == "Path"    { path = $2 }
            $1 == "Default" && $2 == 1 { is_default = 1 }
            is_default && path != "" { print path; exit }
        ' "$profiles_ini")"
    fi

    [[ -n "$profile" ]] || return 1

    echo "$THUNDERBIRD_DIR/$profile"
}

configure_thunderbird() {
    local profile_dir
    local user_js
    local setting
    local name
    local value
    local missing=()

    if ! profile_dir="$(thunderbird_profile_dir)" || [[ ! -d "$profile_dir" ]]; then
        skip_step "No Thunderbird profile yet, open Thunderbird once and re-run setup.sh"
        return 0
    fi

    user_js="$profile_dir/user.js"

    for setting in "${THUNDERBIRD_PREFS[@]}"; do
        read -r name value <<< "$setting"
        grep -qxF "user_pref(\"$name\", $value);" "$user_js" 2> /dev/null \
            || missing+=("$setting")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        skip_step "Already configured"
        return 0
    fi

    for setting in "${missing[@]}"; do
        read -r name value <<< "$setting"
        # A user_pref for the same name would override ours.
        if [[ -f "$user_js" ]] && ! is_dry_run; then
            sed -i "/^user_pref(\"${name//./\\.}\", /d" "$user_js"
        fi
        printf 'user_pref("%s", %s);\n' "$name" "$value" | append_to_file "$user_js"
    done
}
