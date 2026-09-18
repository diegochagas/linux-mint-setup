#!/usr/bin/env bash
#
# Compose sequences from the XCompose file next to this step
# (cedilla with the acute-accent dead key), merged into
# the user's ~/.XCompose without touching other rules.
#

readonly XCOMPOSE_SOURCE="${BASH_SOURCE[0]%/*}/XCompose"
readonly XCOMPOSE_TARGET="$HOME/.XCompose"

# Prints the Compose rules from the repository file that
# are missing from the user's file.
missing_xcompose_rules() {
    local rule

    while IFS= read -r rule; do
        if ! grep -Fqx "$rule" "$XCOMPOSE_TARGET"; then
            echo "$rule"
        fi
    done < <(grep '^<' "$XCOMPOSE_SOURCE")
}

configure_xcompose() {
    local missing

    if ! file_exists "$XCOMPOSE_TARGET"; then
        run cp "$XCOMPOSE_SOURCE" "$XCOMPOSE_TARGET"
        return 0
    fi

    mapfile -t missing < <(missing_xcompose_rules)

    if (( ${#missing[@]} == 0 )); then
        skip_step "Already configured"
        return 0
    fi

    printf '\n%s\n' "${missing[@]}" | append_to_file "$XCOMPOSE_TARGET"
}
