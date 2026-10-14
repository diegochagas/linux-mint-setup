#!/usr/bin/env bash
#
# Private host-side workspace for the Kindle/Calibre workflow. WinBoat must
# share this directory through its own UI or configuration; this script does
# not modify the VM, its disks, or its sharing settings.
#

: "${KINDLE_DEDRM_DIR:=$HOME/Kindle-DeDRM}"
: "${KINDLE_DEDRM_BACKUP_DIR:=}"

backup_kindle_dedrm_keys() {
    local source
    local target
    local backed_up=false

    [[ -n "$KINDLE_DEDRM_BACKUP_DIR" ]] || return 0

    run mkdir -p "$KINDLE_DEDRM_BACKUP_DIR"
    run chmod 700 "$KINDLE_DEDRM_BACKUP_DIR"

    for source in \
        "$KINDLE_DEDRM_DIR/oldbooks.k4i" \
        "$KINDLE_DEDRM_DIR/books.keyfile" \
        "$KINDLE_DEDRM_DIR/storage/.kinf2024"; do
        [[ -f "$source" ]] || continue

        target="$KINDLE_DEDRM_BACKUP_DIR/${source##*/}"
        run chmod 600 "$source"
        run install -m 600 "$source" "$target"
        backed_up=true
    done

    if [[ "$backed_up" == true ]]; then
        print_info "Backed up Kindle key material with mode 0600."
    else
        print_info "No Kindle key material found to back up yet."
    fi
}

configure_kindle_dedrm_workspace() {
    if [[ -d "$KINDLE_DEDRM_DIR/tools" && -d "$KINDLE_DEDRM_DIR/output" && -d "$KINDLE_DEDRM_DIR/backup" ]]; then
        backup_kindle_dedrm_keys
        skip_step "Private workspace already exists"
        return 0
    fi

    run mkdir -p "$KINDLE_DEDRM_DIR/tools" "$KINDLE_DEDRM_DIR/output" "$KINDLE_DEDRM_DIR/backup"

    print_info "Share this directory with WinBoat using WinBoat's own configuration."
    print_info "Do not store Kindle key files in this repository or another public location."

    backup_kindle_dedrm_keys
}
