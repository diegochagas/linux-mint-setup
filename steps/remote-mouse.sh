#!/usr/bin/env bash
#
# Remote Mouse, from its official AMD64 zip download.
#

: "${REMOTE_MOUSE_ZIP_URL:=https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip}"

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

    write_root_file /usr/share/applications/remotemouse.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Remote Mouse
Exec=RemoteMouse
Icon=input-mouse
Terminal=false
Categories=Utility;Network;
EOF
}
