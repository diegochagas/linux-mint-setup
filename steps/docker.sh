#!/usr/bin/env bash
#
# Docker post-install configuration: lets the user run
# Docker without sudo and enables the services.
#

# The user to add to the docker group: the invoking user
# when the setup itself runs under sudo.
docker_target_user() {
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
        echo "$SUDO_USER"
    else
        id -un
    fi
}

docker_group_exists() {
    getent group docker > /dev/null 2>&1
}

docker_services_enabled_and_running() {
    unit_is_enabled_and_active docker.service &&
        unit_is_enabled_and_active containerd.service
}

configure_docker() {
    local user
    local group
    local home
    local config_dir

    user="$(docker_target_user)"
    group="$(id -gn "$user")"
    home="$(getent passwd "$user" | cut -d: -f6)"
    config_dir="$home/.docker"

    if docker_group_exists &&
       user_is_in_group "$user" docker &&
       docker_services_enabled_and_running
    then
        skip_step "Already configured"
        return 0
    fi

    if ! docker_group_exists; then
        run sudo groupadd docker
    fi

    if ! user_is_in_group "$user" docker; then
        run sudo usermod -aG docker "$user"
        print_info "ℹ️ Log out and back in, or run 'newgrp docker', before using Docker without sudo."
    fi

    if directory_exists "$config_dir"; then
        run sudo chown -R "$user:$group" "$config_dir"
        run sudo chmod -R g+rwx "$config_dir"
    fi

    run sudo systemctl enable --now docker.service
    run sudo systemctl enable --now containerd.service
}
