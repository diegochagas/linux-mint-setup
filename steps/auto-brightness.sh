#!/usr/bin/env bash
#
# Auto brightness: phone-style adaptive screen brightness
# for laptops without an ambient light sensor, using the
# webcam as the sensor:
#
#   https://github.com/diegochagas/auto-brightness
#
# Clones the repository to ~/Projects/auto-brightness, puts
# its config in ~/.config/auto-brightness/config.toml and
# installs its systemd user service. The laptop panel is
# set through logind and external monitors over DDC/CI
# with ddcutil (an APT package whose udev rule gives the
# logged-in user access to /dev/i2c-*), so nothing runs as
# root.
#
# The config is copied from AUTO_BRIGHTNESS_CONFIG_FILE
# when set: a copy kept outside Git with the tuned curve,
# per-screen scales and the monitors' names (which include
# their serial numbers). Otherwise auto-brightness detects
# the webcam and backlight and writes its defaults. An
# existing config is never overwritten. Skipped on
# machines without a backlight or a webcam (desktops).
#

: "${AUTO_BRIGHTNESS_REPO:=https://github.com/diegochagas/auto-brightness.git}"
: "${AUTO_BRIGHTNESS_CONFIG_FILE:=}"

# The unit written by scripts/install-service points at
# this clone, so it stays put like homelab-backup's.
readonly AUTO_BRIGHTNESS_DIR="$HOME/Projects/auto-brightness"
readonly AUTO_BRIGHTNESS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/auto-brightness/config.toml"
readonly AUTO_BRIGHTNESS_UNIT="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/auto-brightness.service"

# Set by update_auto_brightness when a pull brought new code.
AUTO_BRIGHTNESS_UPDATED=false

auto_brightness_hardware_present() {
    compgen -G "/sys/class/backlight/*" > /dev/null &&
        compgen -G "/dev/video*" > /dev/null
}

# Fast-forwards an existing clone; a local change or a
# diverged branch keeps the clone as it is.
update_auto_brightness() {
    local before

    before="$(git -C "$AUTO_BRIGHTNESS_DIR" rev-parse HEAD)"
    if ! run git -C "$AUTO_BRIGHTNESS_DIR" pull --ff-only --quiet; then
        print_info "⚠️ Could not update $AUTO_BRIGHTNESS_DIR; using it as it is"
        return 0
    fi

    if [[ "$(git -C "$AUTO_BRIGHTNESS_DIR" rev-parse HEAD)" != "$before" ]]; then
        AUTO_BRIGHTNESS_UPDATED=true
    fi
}

clone_auto_brightness() {
    if directory_exists "$AUTO_BRIGHTNESS_DIR/.git"; then
        update_auto_brightness
        return 0
    fi

    if directory_exists "$AUTO_BRIGHTNESS_DIR"; then
        warn_step "Not a Git repository: $AUTO_BRIGHTNESS_DIR"
        return 1
    fi

    run mkdir -p "$(dirname "$AUTO_BRIGHTNESS_DIR")"
    run git clone "$AUTO_BRIGHTNESS_REPO" "$AUTO_BRIGHTNESS_DIR"
}

# Copies AUTO_BRIGHTNESS_CONFIG_FILE, or lets
# auto-brightness detect the devices and write defaults.
install_auto_brightness_config() {
    if file_exists "$AUTO_BRIGHTNESS_CONFIG"; then
        print_info "⏭️ Keeping $AUTO_BRIGHTNESS_CONFIG"
        return 0
    fi

    if [[ -z "$AUTO_BRIGHTNESS_CONFIG_FILE" ]]; then
        run "$AUTO_BRIGHTNESS_DIR/scripts/setup" --no-dev
        return 0
    fi

    # Writing defaults now would hide the tuned copy for good,
    # since an existing config is never overwritten.
    if ! file_exists "$AUTO_BRIGHTNESS_CONFIG_FILE"; then
        warn_step "$AUTO_BRIGHTNESS_CONFIG_FILE not found (not synced yet?): run the setup again later"
        return 1
    fi

    run mkdir -p "$(dirname "$AUTO_BRIGHTNESS_CONFIG")"
    run cp "$AUTO_BRIGHTNESS_CONFIG_FILE" "$AUTO_BRIGHTNESS_CONFIG"
}

# The ddcutil package's udev rule gives the logged-in user
# /dev/i2c-* only once udev re-runs it (and i2c-dev is
# loaded), which otherwise waits for the next boot.
enable_ddc_access() {
    if ! binary_exists ddcutil; then
        print_info "⏭️ ddcutil not installed: external monitors are left alone"
        return 0
    fi

    run sudo modprobe i2c-dev
    run sudo udevadm trigger --subsystem-match=i2c-dev --action=add
    run sudo udevadm settle
}

# Configured means: config present, unit installed from this
# clone, service running, and no new code since.
auto_brightness_configured() {
    [[ "$AUTO_BRIGHTNESS_UPDATED" == false ]] &&
        file_exists "$AUTO_BRIGHTNESS_CONFIG" &&
        grep -qxF "WorkingDirectory=$AUTO_BRIGHTNESS_DIR" "$AUTO_BRIGHTNESS_UNIT" 2> /dev/null &&
        unit_is_enabled_and_active auto-brightness.service --user
}

configure_auto_brightness() {
    if ! auto_brightness_hardware_present; then
        skip_step "No backlight or webcam on this machine"
        return 0
    fi

    clone_auto_brightness || return 0

    if auto_brightness_configured; then
        skip_step "Already configured"
        return 0
    fi

    install_auto_brightness_config || return 0
    enable_ddc_access
    run "$AUTO_BRIGHTNESS_DIR/scripts/install-service"
}
