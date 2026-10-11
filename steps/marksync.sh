#!/usr/bin/env bash
#
# MarkSync: keeps the bookmarks of Firefox and Chrome in
# sync. It is the Manifest V3 successor of xBrowserSync,
# whose Chrome extension can no longer be installed, and
# uses the same sync service and sync IDs.
#
# The extension is installed in both browsers through
# their enterprise policy files, as "normal_installed":
# installed automatically, but the user can still disable
# it. Creating the sync (or joining the one made on another
# machine) needs a password, so it stays a manual step; see
# the README.
#

: "${MARKSYNC_FIREFOX_ID:=marksync-webext@marksync.org}"
: "${MARKSYNC_FIREFOX_XPI_URL:=https://addons.mozilla.org/firefox/downloads/latest/marksync/latest.xpi}"
: "${MARKSYNC_CHROME_ID:=ajmlmhlkkindginlgpgeeelnimadgckl}"
: "${MARKSYNC_CHROME_UPDATE_URL:=https://clients2.google.com/service/update2/crx}"

# Firefox reads <install dir>/distribution/policies.json on
# every build of it; /etc/firefox/policies only on distro builds.
MARKSYNC_FIREFOX_POLICIES="/usr/lib/firefox/distribution/policies.json"

# Chrome reads this directory from the .deb package, and the Flatpak
# version links the host's files into its sandbox.
MARKSYNC_CHROME_POLICIES="/etc/opt/chrome/policies/managed/linux-mint-setup.json"

MARKSYNC_CHANGED=false
MARKSYNC_FAILED=false

# Merges an extension entry into a JSON policy file, as root,
# leaving every other policy in the file alone. Does nothing
# when the file already has the entry.
#
# Arguments:
#   $1 - Policy file
#   $2 - jq filter that adds the entry, using $id and $url
#   $3 - Extension ID
#   $4 - Extension URL
marksync_merge_policy() {
    local file="$1"
    local filter="$2"
    local id="$3"
    local url="$4"
    local current='{}'
    local updated

    if file_exists "$file"; then
        if ! jq -e . "$file" > /dev/null 2>&1; then
            print_info "⚠️ $file is not valid JSON, fix or remove it and re-run setup.sh"
            MARKSYNC_FAILED=true
            return 0
        fi

        current="$(cat "$file")"
    fi

    updated="$(jq --arg id "$id" --arg url "$url" "$filter" <<< "$current")"

    if [[ "$(jq -S . <<< "$current")" == "$(jq -S . <<< "$updated")" ]]; then
        print_info "⏭️ $file already has MarkSync"
        return 0
    fi

    run sudo mkdir -p "$(dirname "$file")"
    write_root_file "$file" <<< "$updated"
    MARKSYNC_CHANGED=true
}

configure_marksync() {
    local found_browser=false

    MARKSYNC_CHANGED=false
    MARKSYNC_FAILED=false

    if is_apt_installed firefox; then
        found_browser=true

        # $id and $url are jq variables, not shell ones.
        # shellcheck disable=SC2016
        marksync_merge_policy "$MARKSYNC_FIREFOX_POLICIES" \
            '.policies.ExtensionSettings[$id] = {installation_mode: "normal_installed", install_url: $url}' \
            "$MARKSYNC_FIREFOX_ID" "$MARKSYNC_FIREFOX_XPI_URL"
    fi

    if is_apt_installed google-chrome-stable || is_flatpak_installed com.google.Chrome; then
        found_browser=true

        # shellcheck disable=SC2016
        marksync_merge_policy "$MARKSYNC_CHROME_POLICIES" \
            '.ExtensionSettings[$id] = {installation_mode: "normal_installed", update_url: $url}' \
            "$MARKSYNC_CHROME_ID" "$MARKSYNC_CHROME_UPDATE_URL"
    fi

    if [[ "$MARKSYNC_FAILED" == true ]]; then
        warn_step "A policy file could not be updated, see above"
        return 0
    fi

    if [[ "$found_browser" == false ]]; then
        skip_step "Neither Firefox nor Chrome is installed"
        return 0
    fi

    if [[ "$MARKSYNC_CHANGED" == false ]]; then
        skip_step "Already configured"
        return 0
    fi

    print_info "Restart Firefox and Chrome to get the extension, then create or join the sync (README, Step 2)"
}
