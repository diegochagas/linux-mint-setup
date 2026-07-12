# Linux Mint Setup

![Bash](https://img.shields.io/badge/Bash-5%2B-green)
![License](https://img.shields.io/github/license/diegochagas/homelab-backup)
![Version](https://img.shields.io/badge/version-1.0.0-blue)

Personal post-install setup for Linux Mint. Follow the steps below in order.

## Step 1 - Manual Downloads

Complete this before running the setup script:

1. Download [DaVinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve).
2. Extract or place the installer at:

   ```text
   ~/Downloads/DaVinci_Resolve_21.0_Linux/DaVinci_Resolve_21.0_Linux.run
   ```

The setup script installs DaVinci Resolve only when it finds the installer at
that exact path.

## Step 2 - Run the Automated Setup Script

Open a terminal and run:

```bash
wget -O setup.sh https://raw.githubusercontent.com/diegochagas/linux-mint-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

The script asks for the administrator password when it needs `sudo`
permissions. Keep an internet connection active while it runs.

## Step 3 - Manual Post-Install Steps

1. Install the fonts located in the `Softwares` folder.
2. Configure automatic system snapshots:
   `Update Manager > Edit > System Snapshots > Wizard > Next > Next >
Weekly - Keep 4 > Next > Next > Finish`.

## What `setup.sh` Does

The script stops if an unhandled command fails and performs the following
actions:

### System and APT Packages

- Removes Linux Mint's Snap restriction by renaming `nosnap.pref`, when present.
- Adds the official Sublime Text APT repository.
- Updates APT and installs:
  Firefox, ExifTool, VLC, Sublime Text, Git, Node.js, npm, Python 3, curl, jq,
  unzip, xclip, CopyQ, btop, Inkscape, Nextcloud Desktop, FFmpeg, GParted, Tree, ShellCheck, Virtualbox, Docker, Docker Compose, gh, nfs-kernel-server, zbar-tools, and supporting
  libraries.
- On AMD64 systems, installs Remote Mouse and the latest balenaEtcher release.
- On AMD64 and ARM64 systems, installs the latest `immich-go` release.
- On AMD64 systems, installs Claude Desktop from Anthropic's latest x64 `.deb`
  installer.

### Snap Applications

The script installs Snap support and then installs:

- Surfshark
- Visual Studio Code
- Insomnia
- LocalSend

### Flatpak Applications

The script installs Flatpak, adds Flathub, and installs:

- NormCap
- Google Chrome
- Emojify
- Master PDF Editor

### GIMP Ecosystem

The complete GIMP ecosystem lives in its own repository:
[gimp-setup](https://github.com/diegochagas/gimp-setup).

If the GIMP Flatpak is already installed, this step is skipped entirely —
GIMP itself is the marker for the whole ecosystem. To add missing pieces to
an existing GIMP install, run the (idempotent) `gimp-setup/setup.sh`
directly.

Otherwise the script clones that repository and runs its `setup.sh`, which
installs and configures with a single command the features listed in [gimp-setup/docs/](https://github.com/diegochagas/gimp-setup/tree/main/docs)

The repository to clone can be overridden with the `GIMP_SETUP_REPO` variable
in `config.sh`, and the `GEMINI_API_KEY` / `OPENAI_API_KEY` values set there
are forwarded to the GIMP setup for its AI plug-ins. See the
[gimp-setup README](https://github.com/diegochagas/gimp-setup#readme) for
details, configuration and how to add new GIMP features.

### Homelab Backup Automation

After the other setup steps finish, the script clones
[homelab-backup](https://github.com/diegochagas/homelab-backup) to:

```text
~/Projects/homelab-backup
```

It then applies the systemd user timer configuration from `backup.md`:

- Makes `~/Projects/homelab-backup/backup.sh` executable.
- Creates `~/.config/systemd/user/homelab-backup.service`.
- Creates `~/.config/systemd/user/homelab-backup.timer`.
- Reloads the user systemd daemon.
- Enables and starts the timer with
  `systemctl --user enable --now homelab-backup.timer`.

The timer runs the backup daily at 10:00 AM. Because `Persistent=true` is set,
if the computer is powered off at the scheduled time, the backup runs on the
next login.

The repository to clone can be overridden with the `HOMELAB_BACKUP_REPO`
variable in `config.sh`. The clone location remains
`~/Projects/homelab-backup`, matching the systemd unit configuration.

### Other Software

- Installs Tailscale using its official installation script.
- Installs [`immich-go`](https://github.com/simulot/immich-go) to
  `/usr/local/bin/immich-go` on AMD64 and ARM64 systems.
- Installs DaVinci Resolve when its installer is found at the path described in
  Step 1.
- Moves selected bundled DaVinci Resolve libraries into
  `/opt/resolve/libs/oldlibs` to improve compatibility with Linux Mint.
- Installs [Claude Desktop](https://claude.ai/download) on AMD64 systems by
  downloading Anthropic's latest x64 `.deb` installer and installing it with
  APT. The installer registers Anthropic's APT repository so Claude Desktop
  updates with the rest of the system packages.

### Desktop Configuration

The script creates these Cinnamon keyboard shortcuts:

| Shortcut            | Action                                    |
| ------------------- | ----------------------------------------- |
| `Alt + V`           | Toggle CopyQ                              |
| `Alt + T`           | Open NormCap                              |
| `Alt + E`           | Open Emojify                              |
| `Alt + C`           | Copy a screenshot of an area to clipboard |
| `Shift + Super + S` | Copy a screenshot to clipboard            |

It also:

- Configures CopyQ to start automatically.
- Allows unverified Flatpak applications to appear in Software Manager.
- Enables automatic update checks and updates in Update Manager.
- Configures the Homelab Backup systemd user timer after the other setup steps.

## Notes

### GIMP

- Everything GIMP-related is handled by the
  [gimp-setup](https://github.com/diegochagas/gimp-setup) repository. See its
  README for installation details, notes and troubleshooting.
- If GIMP has not been opened before the setup script runs, some GIMP plug-ins
  and features are skipped. Open GIMP once, close it, and re-run `setup.sh`.
- The script downloads software and runs official third-party installation
  scripts, so review `setup.sh` before running it.

### Fixing Random Wi-Fi Disconnects on Linux Mint (MediaTek MT7921)

- Check your Wi-Fi adapter:
  ```bash
  lspci -nnk | grep -A3 -i network
  ```
  If you see something similar to:
  ```text
  MediaTek Corp. MT7921 802.11ax PCI Express Wireless Network Adapter
  Kernel driver in use: mt7921e
  ```
  then this guide applies.
- Install the `iw` utility, if it is not already installed:
  ```bash
  sudo apt update
  sudo apt install iw
  ```
- Check the current power-saving status:
  ```bash
  iw dev wlp63s0 get power_save
  ```
  You may see:
  ```text
  Power save: on
  ```
- Disable Wi-Fi power saving permanently.
  Create the NetworkManager configuration file:
  ```bash
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo nano /etc/NetworkManager/conf.d/wifi-powersave.conf
  ```
  Paste the following:
  ```ini
  [connection]
  wifi.powersave = 2
  ```
  Save and exit with `Ctrl+O`, `Enter`, then `Ctrl+X`.
- Restart NetworkManager:
  ```bash
  sudo systemctl restart NetworkManager
  ```
- Verify that power saving is disabled:
  ```bash
  iw dev wlp63s0 get power_save
  ```
  Expected output:
  ```text
  Power save: off
  ```
- Reboot and verify again:
  ```bash
  iw dev wlp63s0 get power_save
  ```
  If it still shows `Power save: off`, the configuration has been applied
  successfully and should persist across reboots.
  After disabling Wi-Fi power saving, the random network drops stopped occurring
  on the MediaTek MT7921 adapter under Linux Mint.

### ZimaOS Apps

The following apps are installed on ZimaOS, a personal NAS/home server operating system:

- **Cloudflared** – Cloudflare Tunnel client for secure outbound access to self-hosted services.
- **Immich** – Self-hosted photo and video backup and management solution.
- **Jellyfin** – Open-source media server for streaming movies, music, and TV shows.
- **Nextcloud** – Self-hosted cloud platform for file sync, sharing, and collaboration.
- **Pi-hole** – Network-wide DNS-based ad blocker.
- **Tailscale** – VPN mesh network for secure remote access to the NAS.
- **Vaultwarden** – Lightweight, self-hosted Bitwarden-compatible password manager server.

### Other Notes

- Remote Mouse and balenaEtcher are installed only on AMD64 systems.
- `immich-go` is installed only on AMD64 and ARM64 systems.
- Claude Desktop is installed only on AMD64 systems.
- Homelab Backup is cloned to `~/Projects/homelab-backup` and scheduled with a
  user systemd timer.
- Some operations may already be complete when the script is run again. Review
  any errors before retrying.
- Type the cedilla character (`ç`) with `AltGr + ,` (comma).
- The correct audio profile in Sound Settings is `Headset JBL TUNE770NC`.
- Install Python packages only for your user with `python3 -m pip install --user --break-system-packages PACKAGE_NAME`
