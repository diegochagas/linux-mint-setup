#!/usr/bin/env bash
#
# The local AI models this machine's applications share,
# installed by the dedicated local-ai-setup repository:
#
#   https://github.com/diegochagas/local-ai-setup
#
# - ComfyUI with its image models, as the `comfyui` user
#   service: GIMPhoto, comic-skills and photo-restore find
#   it through that service. Skipped unless COMFYUI_DIR is
#   set, because the models are tens of GB.
# - Ollama, the local language-model server: Goose (the
#   steps after this one), comic-skills, tvshow-skills and
#   Digivice.
#
# The repository is cloned and its setup.sh run with the
# COMFYUI_* and OLLAMA_* settings of this setup's config.sh
# passed through the environment. local-ai-setup is
# idempotent, so it runs every time: it skips what is
# already there and resumes interrupted model downloads.
# In a dry run it is still cloned (into the temporary
# workspace) and run with --dry-run, so the preview shows
# what it would do.
#

: "${LOCAL_AI_SETUP_REPO:=https://github.com/diegochagas/local-ai-setup.git}"

# The settings local-ai-setup reads; only those set in
# config.sh are passed, so its own defaults apply to the
# others (COMFYUI_MODEL_SETS set but empty means no models).
readonly LOCAL_AI_SETTINGS=(
    COMFYUI_DIR
    COMFYUI_MODEL_SETS
    COMFYUI_PORT
    COMFYUI_TORCH_INDEX_URL
    OLLAMA_MODELS_DIR
    OLLAMA_INSTALL_URL
)

install_local_ai() {
    local setup_dir name
    local setup_args=()
    local settings=()

    setup_dir="$(make_work_dir local-ai-setup)"

    print_info "➜ git clone --depth 1 $LOCAL_AI_SETUP_REPO $setup_dir"
    if ! git clone --quiet --depth 1 "$LOCAL_AI_SETUP_REPO" "$setup_dir"; then
        warn_step "Could not clone $LOCAL_AI_SETUP_REPO"
        return 0
    fi

    for name in "${LOCAL_AI_SETTINGS[@]}"; do
        if [[ -v "$name" ]]; then
            settings+=("$name=${!name}")
        fi
    done

    if is_dry_run; then
        setup_args+=(--dry-run)
    fi

    print_info "➜ bash $setup_dir/setup.sh ${setup_args[*]}"
    # its own summary lists what failed; this setup carries on
    if ! env "${settings[@]}" bash "$setup_dir/setup.sh" "${setup_args[@]}"; then
        warn_step "local-ai-setup stopped with an error (see above)"
    fi
}
