#!/usr/bin/env bash
#
# Queries and helpers for the local system: files,
# binaries, users, systemd units, PATH and desktop
# autostart entries.
#

ARCHITECTURE="$(dpkg --print-architecture)"
readonly ARCHITECTURE

readonly AUTOSTART_DIR="$HOME/.config/autostart"

binary_exists() {
    command -v "$1" > /dev/null 2>&1
}

file_exists() {
    [[ -f "$1" ]]
}

directory_exists() {
    [[ -d "$1" ]]
}

# Runs a command discarding its output; only the exit status matters.
command_succeeds() {
    "$@" > /dev/null 2>&1
}

# Checks whether a file has exactly the content read from standard input.
file_has_content() {
    file_exists "$1" && cmp -s "$1" -
}

# Checks whether a directory contains a file whose name
# matches a glob pattern, ignoring case.
has_file_matching() {
    local directory="$1"
    local pattern="$2"

    directory_exists "$directory" &&
        find "$directory" -maxdepth 1 -type f -iname "$pattern" -print -quit | grep -q .
}

# Checks whether every file in the source directory has
# an identical copy in the target directory.
directory_files_match() {
    local source_dir="$1"
    local target_dir="$2"
    local file

    directory_exists "$target_dir" || return 1

    for file in "$source_dir"/*; do
        file_exists "$file" || continue
        cmp -s "$file" "$target_dir/${file##*/}" || return 1
    done
}

# Copies every file from the source directory to the target directory.
copy_directory_files() {
    local source_dir="$1"
    local target_dir="$2"

    run mkdir -p "$target_dir"
    run cp -r "$source_dir/." "$target_dir/"
}

user_is_in_group() {
    local user="$1"
    local group="$2"
    local groups

    groups="$(id -nG "$user" 2> /dev/null || true)"

    [[ " $groups " == *" $group "* ]]
}

# Checks whether a systemd unit is both enabled and active.
#
# Arguments:
#   $1 - Unit name
#   $@ - Extra systemctl options, e.g. --user
unit_is_enabled_and_active() {
    local unit="$1"
    shift

    command_succeeds systemctl "$@" is-enabled "$unit" &&
        command_succeeds systemctl "$@" is-active "$unit"
}

# Puts ~/.local/bin on the PATH of this process and of
# future shells. User-local installers (Claude Code,
# AppManager) put their binaries there.
ensure_user_local_bin_on_path() {
    local local_bin="$HOME/.local/bin"
    local shell_file

    case ":$PATH:" in
        *":$local_bin:"*) ;;
        *) export PATH="$local_bin:$PATH" ;;
    esac

    for shell_file in "$HOME/.bashrc" "$HOME/.profile"; do
        if file_exists "$shell_file" && grep -Fq '.local/bin' "$shell_file"; then
            continue
        fi

        {
            echo
            echo "# Added by linux-mint-setup for user-local CLI tools."
            echo 'export PATH="$HOME/.local/bin:$PATH"'
        } | append_to_file "$shell_file"
    done
}

autostart_entry_exists() {
    file_exists "$AUTOSTART_DIR/$1.desktop"
}

# Writes standard input as a desktop autostart entry.
write_autostart_entry() {
    write_file "$AUTOSTART_DIR/$1.desktop"
}
