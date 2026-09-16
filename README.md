# Linux Mint Setup

![Bash](https://img.shields.io/badge/Bash-5%2B-green)
![License](https://img.shields.io/github/license/diegochagas/homelab-backup)
![Version](https://img.shields.io/badge/version-1.0.0-blue)

Personal post-install setup for Linux Mint. Follow the steps below in order.

## Requirements

This assumes Linux Mint is already installed — the script does not
install the OS itself, only what runs on top of it.

| Resource | Linux Mint's own minimum | Comfortable for this script's full install |
| --- | --- | --- |
| RAM | 2 GB (4 GB recommended by Linux Mint) | 8 GB+ (16 GB if you use Docker containers or WinBoat) |
| Disk (free space) | 20 GB (100 GB recommended by Linux Mint) | 60 GB+ — Snap, Flatpak, Docker images and the GIMP ecosystem all add up |
| Display | 1024×768 | — |
| CPU | x86_64 | x86_64 (AMD64) for the full app set; ARM64 gets a reduced set, see below |

- **CPU architecture matters here, not just power.** Some apps this
  script installs are AMD64-only (Remote Mouse, balenaEtcher, WinBoat,
  Claude Desktop), some support AMD64 and ARM64 (`immich-go`, LocalSend,
  AppManager/Wattage), and the rest install on either. On ARM64 the
  script skips the AMD64-only pieces automatically and says so in its
  summary.
- Docker, the [GIMP ecosystem](https://github.com/diegochagas/gimp-setup)
  and WinBoat (a Windows-app compatibility layer) are the heaviest
  consumers of RAM/disk if you actually use them — a machine that skips
  those can get by with less than the "comfortable" numbers above.

## Step 1 - Run the Automated Setup Script

Open a terminal and run:

```bash
wget -O setup.sh https://raw.githubusercontent.com/diegochagas/linux-mint-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

The script asks for the administrator password when it needs `sudo`
permissions. Keep an internet connection active while it runs.

## Step 2 - Manual Post-Install Steps

1. Configure automatic system snapshots:
   `Update Manager > Edit > System Snapshots > Wizard > Next > Next >
Weekly - Keep 4 > Next > Next > Finish`.
2. Open a new terminal and run `claude` once to sign in to Claude Code.

## What `setup.sh` Does

The script stops if an unhandled command fails and performs the following
actions:

### System and APT Packages

- Removes Linux Mint's Snap restriction by renaming `nosnap.pref`, when present.
- Adds the official Sublime Text APT repository.
- Updates APT and installs:
  Firefox, ExifTool, VLC, Sublime Text, Git, Node.js, npm, Python 3, curl, jq, AntiMicroX,
  unrar, unzip, rsync, xclip, FreeRDP X11, libsecret-tools, CopyQ, btop, Inkscape,
  Nextcloud Desktop, FFmpeg, fontconfig, GParted, Tree, ShellCheck, Docker,
  Docker Compose, gh, nfs-kernel-server, zbar-tools, Anki, the TimGM6mb
  SoundFont, and supporting libraries.
- Configures Docker after installation by adding the current user to the
  `docker` group, fixing existing `~/.docker` ownership if needed, and enabling
  and starting the Docker and containerd systemd services. Log out and back in
  before using Docker without `sudo`.
- On AMD64 systems, installs Remote Mouse and the latest balenaEtcher release.
- On AMD64 and ARM64 systems, installs the latest `immich-go` release.
- On AMD64 and ARM64 systems, installs the latest
  [LocalSend](https://localsend.org/) `.deb` release (not the Snap Store
  version — its AppArmor sandboxing breaks NetworkManager access and the
  system tray icon).
- On AMD64 and ARM64 systems, installs
  [AppManager](https://github.com/kem-a/AppManager) and uses it to install the
  [Wattage](https://github.com/v81d/wattage) nightly AppImage from
  `nightly.link`.
- On AMD64 systems, installs [WinBoat](https://winboat.app/) from its AppImage
  release using AppManager.
- Installs [Claude Code](https://code.claude.com/docs/en/terminal-guide) for
  terminal use.
- On AMD64 systems, installs Claude Desktop from Anthropic's latest x64 `.deb`
  installer.

### Snap Applications

The script installs Snap support and then installs:

- Visual Studio Code
- Insomnia

### Flatpak Applications

The script installs Flatpak, adds Flathub, and installs:

- NormCap
- Google Chrome
- Emojify
- Master PDF Editor
- Kdenlive
- Free Download Manager
- Dosage
- EasyRPG Player
- Telegram Desktop
- Surfshark

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
- Installs [AppManager](https://github.com/kem-a/AppManager), then downloads the
  latest successful Wattage `build-appimage.yml` artifact for the current CPU
  architecture and installs the extracted AppImage with
  `app-manager install`.
- Installs [WinBoat](https://winboat.app/) on AMD64 systems by downloading the
  configured AppImage release and installing it with `app-manager install`.
- Installs [Claude Code](https://code.claude.com/docs/en/terminal-guide) using
  Anthropic's Linux terminal installer:
  ```bash
  curl -fsSL https://claude.ai/install.sh | bash
  ```
- Installs [Claude Desktop](https://claude.ai/download) on AMD64 systems by
  downloading Anthropic's latest x64 `.deb` installer and installing it with
  APT. The installer registers Anthropic's APT repository so Claude Desktop
  updates with the rest of the system packages.

Installer and release source URLs, including the WinBoat AppImage URL, can also
be overridden in `config.sh`. See `config.sh.example` for the full list.

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

- Configures `~/.XCompose` so pressing the acute-accent dead key (`´`) followed
  by `c` produces `ç`, and `´` followed by `Shift+C` produces `Ç`. Restart
  applications that were open during setup before testing the new sequence.
- Configures CopyQ to start automatically.
- Configures LocalSend to start automatically, minimized to the system tray.
- Installs the fonts from the `fonts` folder into
  `~/.local/share/fonts/linux-mint-setup` and refreshes the font cache with
  `fc-cache -f`.
- Installs the AntiMicroX controller profiles from `antimicrox/profiles`
  into `~/.config/antimicrox/profiles`:
  ALendaDoHeroi, ApocalypseAcabouAPutaria, DragonBallZFighters, FallGuys,
  Jaspion, MegamanCollection, and SegaMegaDriveEGenesisClassics. When the
  repository files are not available locally, they are downloaded from GitHub.
  Open AntiMicroX, click `Load`, and pick the game's profile before playing.
- Grants EasyRPG Player access to the RPG Maker library set by
  `RPG_MAKER_LIBRARY_DIR` in `config.sh` — a directory with one subfolder per
  game and the shared RTP assets in `RTP/2000` and `RTP/2003` subfolders, e.g.
  a folder synced by Nextcloud — and copies the RTP into EasyRPG's default
  search path together with the TimGM6mb GM soundfont so MIDI music plays.
  Open the games with EasyRPG's built-in game browser by navigating to the
  library folder; saves are written inside each game folder, so progress stays
  synced across machines. If the variable is empty or the library does not
  exist yet, the step is skipped — set the path in `config.sh` and re-run
  `setup.sh`.
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

### ZimaOS Server

Everything related to the ZimaOS home server — the apps it runs and how to
reinstall them with their customizations after a fresh installation — is
handled by the [zimaos-setup](https://github.com/diegochagas/zimaos-setup)
repository. Its data backup and restore chain lives in
[homelab-backup](https://github.com/diegochagas/homelab-backup).

### Other Notes

- Remote Mouse and balenaEtcher are installed only on AMD64 systems.
- `immich-go` is installed only on AMD64 and ARM64 systems.
- LocalSend is installed only on AMD64 and ARM64 systems, from its official
  `.deb` release rather than the Snap Store, and any existing Snap install is
  removed first.
- AppManager and Wattage are installed only on AMD64 and ARM64 systems. WinBoat
  is installed only on AMD64 systems. If a configured AppImage or nightly
  artifact is temporarily unavailable, the script reports that in the summary
  and continues.
- Claude Code is installed with Anthropic's terminal installer. Run `claude`
  once after setup to sign in.
- Claude Desktop is installed only on AMD64 systems.
- Homelab Backup is cloned to `~/Projects/homelab-backup` and scheduled with a
  user systemd timer.
- Some operations may already be complete when the script is run again. Review
  any errors before retrying.
- Type the cedilla character (`ç`) with `´` followed by `c`; type the uppercase
  form (`Ç`) with `´` followed by `Shift+C`. The `English (US, intl., with dead
  keys)` layout must be enabled. The setup script adds these rules to
  `~/.XCompose` and preserves other custom Compose entries.
- The correct audio profile in Sound Settings is `Headset JBL TUNE770NC`.
- Install Python packages only for your user with `python3 -m pip install --user --break-system-packages PACKAGE_NAME`
