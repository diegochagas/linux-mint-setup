#!/usr/bin/env bash
#
# Homelab backup: clones the homelab-backup repository
# and schedules its backup.sh with a systemd user timer
# that runs daily at 10:00 AM (or on the next login, if
# the computer was off).
#

: "${HOMELAB_BACKUP_REPO:=https://github.com/diegochagas/homelab-backup.git}"

# The clone location is fixed: the systemd units below
# refer to it through %h.
readonly HOMELAB_BACKUP_DIR="$HOME/Projects/homelab-backup"

readonly SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
readonly HOMELAB_BACKUP_SERVICE="$SYSTEMD_USER_DIR/homelab-backup.service"
readonly HOMELAB_BACKUP_TIMER="$SYSTEMD_USER_DIR/homelab-backup.timer"

homelab_backup_service_unit() {
    cat << 'EOF'
[Unit]
Description=Homelab Backup

[Service]
Type=oneshot
WorkingDirectory=%h/Projects/homelab-backup
ExecStart=%h/Projects/homelab-backup/backup.sh
EOF
}

homelab_backup_timer_unit() {
    cat << 'EOF'
[Unit]
Description=Run Homelab Backup

[Timer]
OnCalendar=*-*-* 10:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

clone_homelab_backup() {
    if directory_exists "$HOMELAB_BACKUP_DIR/.git"; then
        print_info "⏭️ homelab-backup already cloned"
        return 0
    fi

    if directory_exists "$HOMELAB_BACKUP_DIR"; then
        abort "homelab-backup target exists but is not a Git repository: $HOMELAB_BACKUP_DIR"
    fi

    run mkdir -p "$(dirname "$HOMELAB_BACKUP_DIR")"
    run git clone "$HOMELAB_BACKUP_REPO" "$HOMELAB_BACKUP_DIR"
}

homelab_backup_configured() {
    [[ -x "$HOMELAB_BACKUP_DIR/backup.sh" ]] &&
        homelab_backup_service_unit | file_has_content "$HOMELAB_BACKUP_SERVICE" &&
        homelab_backup_timer_unit | file_has_content "$HOMELAB_BACKUP_TIMER" &&
        unit_is_enabled_and_active homelab-backup.timer --user
}

configure_homelab_backup() {
    clone_homelab_backup

    if homelab_backup_configured; then
        skip_step "Already configured"
        return 0
    fi

    run chmod +x "$HOMELAB_BACKUP_DIR/backup.sh"

    homelab_backup_service_unit | write_file "$HOMELAB_BACKUP_SERVICE"
    homelab_backup_timer_unit | write_file "$HOMELAB_BACKUP_TIMER"

    run systemctl --user daemon-reload
    run systemctl --user enable --now homelab-backup.timer
}
