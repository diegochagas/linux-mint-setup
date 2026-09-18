#!/usr/bin/env bash
#
# Claude Code, from Anthropic's terminal installer. The
# installer updates an existing installation, so it runs
# on every setup.
#

: "${CLAUDE_CODE_INSTALL_URL:=https://claude.ai/install.sh}"

find_claude_code_binary() {
    local versions_dir="$HOME/.local/share/claude/versions"
    local latest

    if binary_exists claude; then
        command -v claude
        return 0
    fi

    if [[ -x "$HOME/.local/bin/claude" ]]; then
        echo "$HOME/.local/bin/claude"
        return 0
    fi

    if directory_exists "$versions_dir"; then
        latest="$(find "$versions_dir" -maxdepth 3 -type f -name claude -perm /111 -print 2> /dev/null | sort -V | tail -n 1 || true)"

        if [[ -n "$latest" ]]; then
            echo "$latest"
            return 0
        fi
    fi

    return 1
}

install_claude_code() {
    ensure_user_local_bin_on_path

    run_remote_script "$CLAUDE_CODE_INSTALL_URL" bash

    if ! is_dry_run && ! find_claude_code_binary > /dev/null; then
        abort "Claude Code installer completed, but the claude binary was not found."
    fi
}
