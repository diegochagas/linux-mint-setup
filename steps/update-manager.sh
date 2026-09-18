#!/usr/bin/env bash
#
# Update Manager and Software Manager settings.
#

# Settings as "schema key value".
UPDATE_MANAGER_SETTINGS=(
    "com.linuxmint.install allow-unverified-flatpaks true"
    "com.linuxmint.updates refresh-schedule-enabled true"
    "com.linuxmint.updates auto-update-flatpaks true"
    "com.linuxmint.updates auto-update-cinnamon-spices true"
)

update_manager_configured() {
    local setting
    local schema
    local key
    local value

    for setting in "${UPDATE_MANAGER_SETTINGS[@]}"; do
        read -r schema key value <<< "$setting"
        [[ "$(gsettings get "$schema" "$key")" == "$value" ]] || return 1
    done
}

configure_update_manager() {
    local setting
    local schema
    local key
    local value

    if update_manager_configured; then
        skip_step "Already configured"
        return 0
    fi

    for setting in "${UPDATE_MANAGER_SETTINGS[@]}"; do
        read -r schema key value <<< "$setting"
        run gsettings set "$schema" "$key" "$value"
    done
}
