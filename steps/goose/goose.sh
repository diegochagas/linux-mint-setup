#!/usr/bin/env bash
#
# Goose, a free, open-source AI agent (a local alternative
# to Claude Cowork), running a local model through Ollama:
#
# - Goose CLI in ~/.local/bin, from Block's installer.
# - Goose Desktop from its latest AMD64 .deb release,
#   verified against the SHA-256 GitHub records for it.
# - The local model: GOOSE_OLLAMA_BASE_MODEL is pulled and
#   a copy named GOOSE_OLLAMA_MODEL is created with a
#   GOOSE_OLLAMA_CONTEXT-token context. Ollama's default
#   4096-token context is too small for Goose's own prompt.
# - Goose's config.yaml (provider, model, approval mode,
#   turn limit and extensions; see goose-config.py) and the
#   global .goosehints next to this step.
#
# The Desktop package installs /usr/bin/goose as a link to
# the Desktop app, so ~/.local/bin must come first on the
# PATH for the goose command to run the CLI.
#

: "${GOOSE_CLI_INSTALL_URL:=https://github.com/block/goose/releases/download/stable/download_cli.sh}"
: "${GOOSE_RELEASES_API_URL:=https://api.github.com/repos/block/goose/releases/latest}"
: "${GOOSE_OLLAMA_BASE_MODEL:=qwen3:30b-a3b-instruct-2507-q4_K_M}"
: "${GOOSE_OLLAMA_MODEL:=qwen3-instruct-32k}"
: "${GOOSE_OLLAMA_CONTEXT:=32768}"
: "${GOOSE_SEARXNG_URL:=}"

readonly GOOSE_STEP_DIR="${BASH_SOURCE[0]%/*}"
readonly GOOSE_CLI="$HOME/.local/bin/goose"
readonly GOOSE_CONFIG_DIR="$HOME/.config/goose"
readonly GOOSE_CONFIG="$GOOSE_CONFIG_DIR/config.yaml"
readonly GOOSE_HINTS="$GOOSE_CONFIG_DIR/.goosehints"

# The default model needs about 20 GB for its weights and
# context, shared between GPU memory and RAM.
readonly GOOSE_DEFAULT_MODEL_MIN_RAM_GB=24

install_goose_cli() {
    ensure_user_local_bin_on_path

    if [[ -x "$GOOSE_CLI" ]]; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 arm64 || return 0

    CONFIGURE=false run_remote_script "$GOOSE_CLI_INSTALL_URL" bash
}

install_goose_desktop() {
    local url
    local expected_checksum
    local actual_checksum
    local package

    if is_apt_installed goose; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    # "_amd64.deb" leaves out the "_amd64-vulkan.deb" variant.
    url="$(github_release_asset_url "$GOOSE_RELEASES_API_URL" "_amd64.deb")"
    expected_checksum="$(github_release_asset_sha256 "$GOOSE_RELEASES_API_URL" "_amd64.deb")"

    if [[ -z "$url" || -z "$expected_checksum" ]]; then
        warn_step "Release package or checksum unavailable"
        return 0
    fi

    package="$(make_work_dir goose-desktop)/goose.deb"
    download_file "$url" "$package"

    if ! is_dry_run; then
        actual_checksum="$(sha256sum "$package" | awk '{ print $1 }')"

        if [[ "$actual_checksum" != "$expected_checksum" ]]; then
            warn_step "Checksum verification failed"
            return 0
        fi
    fi

    run sudo apt install -y "$package"
}

goose_model_modelfile() {
    cat << EOF
FROM $GOOSE_OLLAMA_BASE_MODEL
PARAMETER num_ctx $GOOSE_OLLAMA_CONTEXT
EOF
}

goose_model_exists() {
    ollama show --parameters "$GOOSE_OLLAMA_MODEL" 2> /dev/null |
        grep -Eq "^num_ctx[[:space:]]+$GOOSE_OLLAMA_CONTEXT\$"
}

# Waits up to 30 seconds for the Ollama API, which may be
# restarting after the Ollama steps.
wait_for_ollama() {
    for _ in {1..30}; do
        command_succeeds ollama list && return 0
        sleep 1
    done

    return 1
}

total_ram_gb() {
    awk '/^MemTotal:/ { printf "%d", $2 / 1024 / 1024 + 0.5 }' /proc/meminfo
}

configure_goose_model() {
    local modelfile

    if ! binary_exists ollama; then
        skip_step "Ollama not installed"
        return 0
    fi

    if ! wait_for_ollama; then
        warn_step "Ollama is not responding"
        print_info "   Check: systemctl status ollama"
        return 0
    fi

    if goose_model_exists; then
        skip_step "Already configured"
        return 0
    fi

    if [[ "$GOOSE_OLLAMA_BASE_MODEL" == "qwen3:30b-a3b-instruct-2507-q4_K_M" ]] &&
        (($(total_ram_gb) < GOOSE_DEFAULT_MODEL_MIN_RAM_GB)); then
        warn_step "The default model needs ${GOOSE_DEFAULT_MODEL_MIN_RAM_GB} GB of RAM"
        print_info "   Set GOOSE_OLLAMA_BASE_MODEL to a smaller model (e.g. qwen3:8b) in config.sh."
        return 0
    fi

    modelfile="$(make_work_dir goose-model)/Modelfile"

    run ollama pull "$GOOSE_OLLAMA_BASE_MODEL"
    goose_model_modelfile | write_file "$modelfile"
    run ollama create "$GOOSE_OLLAMA_MODEL" -f "$modelfile"
}

goose_config_content() {
    python3 "$GOOSE_STEP_DIR/goose-config.py" "$GOOSE_CONFIG" "$GOOSE_OLLAMA_MODEL" "$GOOSE_SEARXNG_URL"
}

configure_goose() {
    local config

    # python3-yaml comes from the APT step, which a dry run
    # only simulates.
    if is_dry_run && ! command_succeeds python3 -c 'import yaml'; then
        print_info "➜ Write $GOOSE_CONFIG"
        print_info "➜ Write $GOOSE_HINTS"
        return 0
    fi

    config="$(goose_config_content)"

    if file_has_content "$GOOSE_HINTS" < "$GOOSE_STEP_DIR/goosehints" &&
        printf '%s\n' "$config" | file_has_content "$GOOSE_CONFIG"; then
        skip_step "Already configured"
        return 0
    fi

    if file_exists "$GOOSE_CONFIG" && ! printf '%s\n' "$config" | file_has_content "$GOOSE_CONFIG"; then
        run cp "$GOOSE_CONFIG" "$GOOSE_CONFIG.bak"
    fi

    printf '%s\n' "$config" | write_file "$GOOSE_CONFIG"
    write_file "$GOOSE_HINTS" < "$GOOSE_STEP_DIR/goosehints"
}
