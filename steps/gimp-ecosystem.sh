#!/usr/bin/env bash
#
# The complete GIMP ecosystem (Flatpak GIMP, plug-ins,
# resources, extra features and the local AI models
# behind its AI tools: ComfyUI), installed by the
# dedicated gimp-setup repository:
#
#   https://github.com/diegochagas/gimp-setup
#
# GIMP itself is the marker for the whole ecosystem: if
# the GIMP Flatpak is already installed, nothing
# GIMP-related is (re)installed. The exception is
# ComfyUI: while COMFYUI_DIR is set and ComfyUI is not
# installed there yet, gimp-setup still runs, so it can
# install it. The per-feature detection lives in
# gimp-setup's own idempotent setup.sh; run it directly
# to add missing pieces to an existing install.
#

: "${GIMP_SETUP_REPO:=https://github.com/diegochagas/gimp-setup.git}"
: "${COMFYUI_DIR:=}"
: "${COMFYUI_MODEL_SETS=qwen,klein}"
: "${COMFYUI_PORT:=8188}"

# ComfyUI is installed by gimp-setup (and only on amd64), so a GIMP that
# is already there is not a marker while ComfyUI is wanted but missing.
gimp_ecosystem_needs_comfyui() {
    [[ -n "$COMFYUI_DIR" && "$ARCHITECTURE" == "amd64" ]] || return 1

    ! { file_exists "$COMFYUI_DIR/main.py" && file_exists "$COMFYUI_DIR/.venv/bin/python"; }
}

install_gimp_ecosystem() {
    local setup_dir
    local setup_args=()

    if is_flatpak_installed org.gimp.GIMP && ! gimp_ecosystem_needs_comfyui; then
        skip_step "Already installed"
        return 0
    fi

    setup_dir="$(make_work_dir gimp-setup)"

    run git clone --depth 1 "$GIMP_SETUP_REPO" "$setup_dir"

    if is_dry_run; then
        setup_args+=(--dry-run)
    fi

    # The ComfyUI settings are read by gimp-setup's ComfyUI feature (and
    # the address of that ComfyUI by its AI plug-ins) from the environment.
    export COMFYUI_DIR COMFYUI_MODEL_SETS COMFYUI_PORT

    run bash "$setup_dir/setup.sh" "${setup_args[@]}"
}
