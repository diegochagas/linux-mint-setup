#!/usr/bin/env bash
#
# Checks that run before any step: required commands,
# administrator privileges, internet access and the
# operating system.
#

readonly REQUIRED_COMMANDS=(
    curl
    tar
    sudo
    apt
    dpkg
    gpg
    systemctl
)

check_dependencies() {
    local command
    local missing=()

    print_info "Checking dependencies..."

    for command in "${REQUIRED_COMMANDS[@]}"; do
        if ! binary_exists "$command"; then
            missing+=("$command")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        print_info "❌ Missing required dependencies:"
        for command in "${missing[@]}"; do
            print_info "  • $command"
        done
        print_info
        abort "Please install the missing dependencies and run the script again."
    fi

    print_info "✅ Dependencies OK"
    print_info
}

check_sudo() {
    print_info "Checking administrator privileges..."

    if is_dry_run; then
        print_info "⏭️ Skipped (dry-run)"
        print_info
        return 0
    fi

    if ! sudo -v > /dev/null 2>&1; then
        abort "Administrator privileges are required."
    fi

    print_info "✅ OK"
    print_info
}

check_internet_connection() {
    print_info "Checking internet connection..."

    if ! curl -Is https://github.com > /dev/null 2>&1; then
        print_info "❌ No internet connection."
        print_info
        abort "Please connect to the internet and run the script again."
    fi

    print_info "✅ Connected"
    print_info
}

check_linux_mint_version() {
    local os_name
    local version

    print_info "Checking operating system..."

    os_name="$(awk -F= '$1 == "NAME" { gsub(/"/, "", $2); print $2 }' /etc/os-release)"
    version="$(awk -F= '$1 == "VERSION_ID" { gsub(/"/, "", $2); print $2 }' /etc/os-release)"

    if [[ "$os_name" != "Linux Mint" ]]; then
        abort "Unsupported operating system: $os_name"
    fi

    print_info "✅ $os_name $version detected"
    print_info
}

run_preflight_checks() {
    print_section "Initialization"

    check_dependencies
    check_sudo
    check_internet_connection
    check_linux_mint_version
}
