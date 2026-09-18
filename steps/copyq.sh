#!/usr/bin/env bash
#
# CopyQ autostart.
#

configure_copyq() {
    if autostart_entry_exists copyq; then
        skip_step "Already configured"
        return 0
    fi

    write_autostart_entry copyq << 'EOF'
[Desktop Entry]
Type=Application
Name=CopyQ
Exec=copyq --start-server hide
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
}
