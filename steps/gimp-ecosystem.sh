#!/usr/bin/env bash
#
# The complete GIMP ecosystem (Flatpak GIMP, plug-ins,
# resources and extra features), installed by the
# dedicated gimp-setup repository:
#
#   https://github.com/diegochagas/gimp-setup
#
# GIMP itself is the marker for the whole ecosystem: if
# the GIMP Flatpak is already installed, nothing
# GIMP-related is (re)installed. The per-feature
# detection lives in gimp-setup's own idempotent
# setup.sh; run it directly to add missing pieces to an
# existing install.
#

: "${GIMP_SETUP_REPO:=https://github.com/diegochagas/gimp-setup.git}"
: "${GEMINI_API_KEY:=}"
: "${OPENAI_API_KEY:=}"

install_gimp_ecosystem() {
    local setup_dir
    local setup_args=()

    if is_flatpak_installed org.gimp.GIMP; then
        skip_step "Already installed"
        return 0
    fi

    setup_dir="$(make_work_dir gimp-setup)"

    run git clone --depth 1 "$GIMP_SETUP_REPO" "$setup_dir"

    if is_dry_run; then
        setup_args+=(--dry-run)
    fi

    # The API keys are forwarded to gimp-setup for its AI plug-ins.
    export GEMINI_API_KEY OPENAI_API_KEY

    run bash "$setup_dir/setup.sh" "${setup_args[@]}"
}
