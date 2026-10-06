#!/usr/bin/env bash
#
# The complete GIMP ecosystem (Flatpak GIMP, plug-ins,
# resources and extra features), installed by the dedicated
# gimp-setup repository:
#
#   https://github.com/diegochagas/gimp-setup
#
# GIMP's AI tools run on the local ComfyUI installed by the
# ComfyUI steps before this one (steps/comfyui); gimp-setup
# finds it through its `comfyui` service, adds its own
# ComfyUI node to it and starts it with GIMP.
#
# GIMP itself is the marker for the whole ecosystem: if the
# GIMP Flatpak is already installed, nothing GIMP-related is
# (re)installed. The exception is a ComfyUI installed after
# GIMP: gimp-setup still runs, so its AI tools get their
# ComfyUI node and the start with GIMP. The per-feature
# detection lives in gimp-setup's own idempotent setup.sh;
# run it directly to add missing pieces to an existing
# install.
#

: "${GIMP_SETUP_REPO:=https://github.com/diegochagas/gimp-setup.git}"

# A ComfyUI is installed (steps/comfyui) but gimp-setup has
# not added its node to it yet.
gimp_ecosystem_needs_comfyui_node() {
    [[ -n "${COMFYUI_DIR:-}" ]] &&
        file_exists "$COMFYUI_DIR/main.py" &&
        ! directory_exists "$COMFYUI_DIR/custom_nodes/gimp_setup_nodes"
}

install_gimp_ecosystem() {
    local setup_dir
    local setup_args=()

    if is_flatpak_installed org.gimp.GIMP && ! gimp_ecosystem_needs_comfyui_node; then
        skip_step "Already installed"
        return 0
    fi

    setup_dir="$(make_work_dir gimp-setup)"

    run git clone --depth 1 "$GIMP_SETUP_REPO" "$setup_dir"

    if is_dry_run; then
        setup_args+=(--dry-run)
    fi

    run bash "$setup_dir/setup.sh" "${setup_args[@]}"
}
