#!/usr/bin/env bash
#
# Remote Mouse, from its official AMD64 zip download.
#

: "${REMOTE_MOUSE_ZIP_URL:=https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip}"

# Remote Mouse loads its tray icon from images/ relative to the working
# directory, and desktop launchers (autostart and the menu) start programs
# from $HOME and ignore Path=, so both entries cd into the install directory
# first. Without it the tray shows a "missing icon" warning.
readonly REMOTE_MOUSE_EXEC='sh -c "cd /opt/remotemouse && exec ./RemoteMouse"'

install_remote_mouse() {
    local work_dir

    if binary_exists RemoteMouse; then
        skip_step "Already installed"
        return 0
    fi

    require_architecture amd64 || return 0

    work_dir="$(make_work_dir remote-mouse)"

    download_file "$REMOTE_MOUSE_ZIP_URL" "$work_dir/remotemouse.zip"
    run unzip -q "$work_dir/remotemouse.zip" -d "$work_dir/app"
    run sudo install -d /opt/remotemouse
    run sudo cp -a "$work_dir/app/." /opt/remotemouse/
    run sudo ln -sf /opt/remotemouse/RemoteMouse /usr/local/bin/RemoteMouse
}

remote_mouse_entry() {
    cat << EOF
[Desktop Entry]
Type=Application
Name=Remote Mouse
Exec=$REMOTE_MOUSE_EXEC
Path=/opt/remotemouse
Icon=/opt/remotemouse/images/icon_linux_taskbar_green@3x.png
Terminal=false
Categories=Utility;Network;
X-GNOME-Autostart-enabled=true
EOF
}

configure_remote_mouse_launchers() {
    local menu_entry=/usr/share/applications/remotemouse.desktop
    local autostart_entry="$AUTOSTART_DIR/remotemouse.desktop"

    if ! directory_exists /opt/remotemouse; then
        skip_step "Remote Mouse not installed"
        return 0
    fi

    if file_has_content "$menu_entry" < <(remote_mouse_entry) &&
        file_has_content "$autostart_entry" < <(remote_mouse_entry); then
        skip_step "Already configured"
        return 0
    fi

    remote_mouse_entry | write_root_file "$menu_entry"
    remote_mouse_entry | write_autostart_entry remotemouse
}
