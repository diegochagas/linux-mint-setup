#!/usr/bin/env bash
#
# Git config includes: adds the files listed in
# GIT_CONFIG_INCLUDES to the global Git configuration
# (include.path in ~/.gitconfig), e.g. per-repository
# settings kept in a folder synced by Nextcloud.
#
# Git skips an include whose file does not exist yet, so
# files that are still syncing take effect as soon as
# they arrive, without running the setup again.
#

: "${GIT_CONFIG_INCLUDES:=}"

git_config_include_paths() {
    local path

    tr ',' '\n' <<< "$GIT_CONFIG_INCLUDES" | while IFS= read -r path; do
        # Trim surrounding whitespace.
        path="${path#"${path%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"
        [[ -n "$path" ]] && echo "$path"
    done
}

git_config_has_include() {
    git config --global --get-all include.path 2> /dev/null | grep -Fqx -- "$1"
}

git_config_includes_configured() {
    local path

    while IFS= read -r path; do
        git_config_has_include "$path" || return 1
    done < <(git_config_include_paths)
}

configure_git_config_includes() {
    local path

    if [[ -z "$(git_config_include_paths)" ]]; then
        skip_step "GIT_CONFIG_INCLUDES not set"
        return 0
    fi

    if git_config_includes_configured; then
        skip_step "Already configured"
        return 0
    fi

    while IFS= read -r path; do
        git_config_has_include "$path" && continue
        run git config --global --add include.path "$path"
    done < <(git_config_include_paths)
}
