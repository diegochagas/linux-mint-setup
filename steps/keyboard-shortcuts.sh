#!/usr/bin/env bash
#
# Cinnamon custom keyboard shortcuts.
#

readonly KEYBINDINGS_PATH="/org/cinnamon/desktop/keybindings"

# Shortcuts as "name|command|binding", assigned to the
# custom0, custom1, ... slots in this order.
KEYBOARD_SHORTCUTS=(
    "CopyQ Toggle|copyq toggle|<Alt>v"
    "NormCap|/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=normcap com.github.dynobo.normcap|<Alt>t"
    "Emojify|/usr/bin/flatpak run xyz.riothedev.emojify|<Alt>e"
)

dconf_read() {
    dconf read "$1" 2> /dev/null || true
}

shortcut_slot() {
    echo "$KEYBINDINGS_PATH/custom-keybindings/custom$1"
}

# Prints the dconf list of every shortcut slot: ['custom0', 'custom1', ...]
shortcut_slot_list() {
    local index
    local slots=()
    local joined

    for index in "${!KEYBOARD_SHORTCUTS[@]}"; do
        slots+=("'custom$index'")
    done

    printf -v joined '%s, ' "${slots[@]}"
    echo "[${joined%, }]"
}

shortcut_matches() {
    local slot="$1"
    local name="$2"
    local command="$3"
    local binding="$4"

    [[ "$(dconf_read "$slot/name")" == "'$name'" ]] &&
        [[ "$(dconf_read "$slot/command")" == "'$command'" ]] &&
        [[ "$(dconf_read "$slot/binding")" == "['$binding']" ]]
}

keyboard_shortcuts_configured() {
    local index
    local name
    local command
    local binding

    if [[ "$(dconf_read "$KEYBINDINGS_PATH/custom-list")" != "$(shortcut_slot_list)" ]]; then
        return 1
    fi

    for index in "${!KEYBOARD_SHORTCUTS[@]}"; do
        IFS="|" read -r name command binding <<< "${KEYBOARD_SHORTCUTS[$index]}"
        shortcut_matches "$(shortcut_slot "$index")" "$name" "$command" "$binding" || return 1
    done
}

configure_keyboard_shortcuts() {
    local index
    local slot
    local name
    local command
    local binding

    if keyboard_shortcuts_configured; then
        skip_step "Already configured"
        return 0
    fi

    for index in "${!KEYBOARD_SHORTCUTS[@]}"; do
        IFS="|" read -r name command binding <<< "${KEYBOARD_SHORTCUTS[$index]}"
        slot="$(shortcut_slot "$index")"

        run dconf write "$slot/name" "'$name'"
        run dconf write "$slot/command" "'$command'"
        run dconf write "$slot/binding" "['$binding']"
    done

    run dconf write "$KEYBINDINGS_PATH/custom-list" "$(shortcut_slot_list)"
}
