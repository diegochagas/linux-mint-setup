#!/usr/bin/env bash
#
# The long-context Ollama model that games-extractor uses
# for its translations (its OLLAMA_MODEL default):
#
# - TRANSLATION_MODEL_BASE is pulled and a copy named
#   TRANSLATION_MODEL_NAME is created with a
#   TRANSLATION_MODEL_CONTEXT-token context. Ollama's
#   default 4096-token context is too small for the
#   translation prompts.
#
# Ollama itself comes from the Local AI step.
#

: "${TRANSLATION_MODEL_BASE:=qwen3:30b-a3b-instruct-2507-q4_K_M}"
: "${TRANSLATION_MODEL_NAME:=qwen3-instruct-32k}"
: "${TRANSLATION_MODEL_CONTEXT:=32768}"

# The default model needs about 20 GB for its weights and
# context, shared between GPU memory and RAM.
readonly TRANSLATION_MODEL_MIN_RAM_GB=24

translation_model_modelfile() {
    cat << MODELFILE
FROM $TRANSLATION_MODEL_BASE
PARAMETER num_ctx $TRANSLATION_MODEL_CONTEXT
MODELFILE
}

translation_model_exists() {
    ollama show --parameters "$TRANSLATION_MODEL_NAME" 2> /dev/null |
        grep -Eq "^num_ctx[[:space:]]+$TRANSLATION_MODEL_CONTEXT\$"
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

configure_translation_model() {
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

    if translation_model_exists; then
        skip_step "Already configured"
        return 0
    fi

    if [[ "$TRANSLATION_MODEL_BASE" == "qwen3:30b-a3b-instruct-2507-q4_K_M" ]] &&
        (($(total_ram_gb) < TRANSLATION_MODEL_MIN_RAM_GB)); then
        warn_step "The default model needs ${TRANSLATION_MODEL_MIN_RAM_GB} GB of RAM"
        print_info "   Set TRANSLATION_MODEL_BASE to a smaller model (e.g. qwen3:8b) in config.sh."
        return 0
    fi

    modelfile="$(make_work_dir translation-model)/Modelfile"

    run ollama pull "$TRANSLATION_MODEL_BASE"
    translation_model_modelfile | write_file "$modelfile"
    run ollama create "$TRANSLATION_MODEL_NAME" -f "$modelfile"
}
