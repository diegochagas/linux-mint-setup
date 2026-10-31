#!/usr/bin/env bash
#
# ai-memory, long-term memory for AI coding agents
# (Claude Code, Codex, Gemini CLI, Copilot CLI, Hermes
# and others), from akitaonrails/ai-memory.
#
# The install script downloads the release binary,
# verifies its checksum, unpacks it under
# ~/.local/lib/ai-memory and links ~/.local/bin/ai-memory.
# It replaces an existing release in place, so it also
# serves as the upgrade path and runs on every setup.
#
# `ai-memory setup` then creates the data directory,
# installs a systemd --user service for the memory
# server and wires hooks, MCP and skills into every
# agent it detects under $HOME. Re-running it changes
# nothing, and it writes a timestamped backup beside
# every agent config it touches.
#

: "${AI_MEMORY_INSTALL_URL:=https://github.com/akitaonrails/ai-memory/releases/latest/download/install.sh}"
: "${AI_MEMORY_AGENTS:=}"

install_ai_memory() {
    ensure_user_local_bin_on_path

    run_remote_script "$AI_MEMORY_INSTALL_URL" sh

    if ! is_dry_run && ! binary_exists ai-memory; then
        abort "ai-memory installer completed, but the ai-memory binary was not found."
    fi
}

configure_ai_memory() {
    local -a setup_args=(setup --yes)
    local agent

    if ! is_dry_run && ! binary_exists ai-memory; then
        warn_step "ai-memory is not installed"
        return 0
    fi

    # Agent detection looks for each harness's config under
    # $HOME, so this step runs after the agent CLIs are
    # installed. AI_MEMORY_AGENTS, when set, wires exactly
    # those agents instead of the detected ones.
    for agent in $AI_MEMORY_AGENTS; do
        setup_args+=(--agent "$agent")
    done

    run ai-memory "${setup_args[@]}"
}
