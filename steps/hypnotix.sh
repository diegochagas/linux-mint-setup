#!/usr/bin/env bash
#
# Hypnotix IPTV player and the Brazilian IPTV-ORG M3U provider.
#

readonly HYPNOTIX_PROVIDER_NAME="IPTV-ORG"
readonly HYPNOTIX_PROVIDER_URL="https://iptv-org.github.io/iptv/countries/br.m3u"
readonly HYPNOTIX_PROVIDER="${HYPNOTIX_PROVIDER_NAME}:::url:::${HYPNOTIX_PROVIDER_URL}:::::::::"

install_hypnotix() {
    if is_apt_installed hypnotix; then
        skip_step "Already installed"
        return 0
    fi

    run sudo apt install -y hypnotix
}

hypnotix_provider_configured() {
    local providers

    providers="$(gsettings get org.x.hypnotix providers)"
    [[ "$providers" == *"'$HYPNOTIX_PROVIDER'"* ]]
}

configure_hypnotix_provider() {
    if ! is_apt_installed hypnotix; then
        skip_step "Hypnotix is not installed"
        return 0
    fi

    if hypnotix_provider_configured; then
        skip_step "IPTV-ORG provider already configured"
        return 0
    fi

    # Hypnotix stores providers as a GSettings string array. Preserve every
    # existing provider while replacing any older entry with this same name.
    run python3 -c '
import ast
import subprocess
import sys

provider = sys.argv[1]
provider_name = provider.partition(":::")[0]
providers = ast.literal_eval(subprocess.check_output(
    ["gsettings", "get", "org.x.hypnotix", "providers"], text=True).strip()
)
providers = [item for item in providers if item.partition(":::")[0] != provider_name]
providers.insert(0, provider)
subprocess.run(
    ["gsettings", "set", "org.x.hypnotix", "providers", repr(providers)], check=True
)
' "$HYPNOTIX_PROVIDER"
}
