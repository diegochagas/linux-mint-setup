#!/usr/bin/env python3
"""Print Goose's config.yaml with the settings linux-mint-setup manages.

Usage: goose-config.py CONFIG_PATH MODEL [SEARXNG_URL]

Reads the existing config (if any) and prints it with:

- the Ollama provider selected, using MODEL;
- a safe approval mode and a turn limit, only when not set yet, so
  choices made later in Goose Desktop are kept;
- the Developer, Browser, SearXNG and IMAP extensions, each added
  only when no extension running the same server exists yet. SearXNG
  is added only when SEARXNG_URL is given. IMAP is added disabled:
  its 40 tools use a large part of a local model's context, so it is
  meant to be turned on only for email tasks.

The config file itself is written by the calling shell step, which
compares this output with the current file to stay idempotent.
"""

import os
import sys

import yaml


def stdio_extension(name, description, package, enabled=True, envs=None):
    return {
        "enabled": enabled,
        "type": "stdio",
        "name": name,
        "description": description,
        "cmd": "npx",
        "args": ["-y", package],
        "envs": envs or {},
        "env_keys": [],
        "timeout": 300,
        "cwd": None,
        "bundled": None,
    }


def has_extension_running(extensions, package):
    for extension in extensions.values():
        command = [str(extension.get("cmd") or "")] + [str(arg) for arg in extension.get("args") or []]
        if any(package in part for part in command):
            return True
    return False


def main():
    config_path, model = sys.argv[1], sys.argv[2]
    searxng_url = sys.argv[3] if len(sys.argv) > 3 else ""

    config = {}
    if os.path.exists(config_path):
        with open(config_path, encoding="utf-8") as file:
            config = yaml.safe_load(file) or {}

    config["active_provider"] = "ollama"
    providers = config.setdefault("providers", {}) or {}
    config["providers"] = providers
    ollama = providers.setdefault("ollama", {}) or {}
    providers["ollama"] = ollama
    ollama.update({"enabled": True, "model": model, "configured": True})
    config.setdefault("OLLAMA_HOST", "localhost")

    config.setdefault("GOOSE_MODE", "smart_approve")
    config.setdefault("GOOSE_MAX_TURNS", 50)

    extensions = config.setdefault("extensions", {}) or {}
    config["extensions"] = extensions

    extensions.setdefault("developer", {
        "enabled": True,
        "type": "platform",
        "name": "developer",
        "description": "Write and edit files, and execute shell commands",
        "display_name": "Developer",
        "bundled": True,
    })

    if not has_extension_running(extensions, "open-browser-control"):
        extensions["browser"] = stdio_extension(
            "browser",
            "Controls Firefox or Chrome through the Open Browser Control add-on",
            "open-browser-control",
        )

    if searxng_url and not has_extension_running(extensions, "mcp-searxng"):
        extensions["searxng"] = stdio_extension(
            "SearXNG Search",
            "Web search through a SearXNG instance",
            "mcp-searxng",
            envs={"SEARXNG_URL": searxng_url},
        )

    if not has_extension_running(extensions, "imap-mcp-server"):
        extensions["imap"] = stdio_extension(
            "IMAP Email",
            "Read and manage email (accounts in ~/.imap-mcp)",
            "imap-mcp-server",
            enabled=False,
        )

    yaml.safe_dump(config, sys.stdout, sort_keys=False, allow_unicode=True, default_flow_style=False)


if __name__ == "__main__":
    main()
