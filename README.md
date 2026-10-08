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
| Disk (free space) | 20 GB (100 GB recommended by Linux Mint) | 60 GB+ — Snap, Flatpak, Docker images and GIMPhoto all add up |
| Display | 1024×768 | — |
| CPU | x86_64 | x86_64 (AMD64) for the full app set; ARM64 gets a reduced set, see below |

- **CPU architecture matters here, not just power.** Some apps this
  script installs are AMD64-only (Remote Mouse, balenaEtcher, WinBoat,
  Claude Desktop), some support AMD64 and ARM64 (`immich-go`, LocalSend,
  AppManager/Wattage), and the rest install on either. On ARM64 the
  script skips the AMD64-only pieces automatically and says so in its
  summary.
- Docker, [GIMPhoto](https://github.com/diegochagas/gimphoto)
  and WinBoat (a Windows-app compatibility layer) are the heaviest
  consumers of RAM/disk if you actually use them — a machine that skips
  those can get by with less than the "comfortable" numbers above.
- The [local image models](#local-ai-models-comfyui-and-ollama)
  (ComfyUI) are the heaviest
  download of all: ComfyUI plus the default model sets is about 42 GB on
  disk and needs an NVIDIA GPU. They are skipped unless `COMFYUI_DIR` is
  set in `config.sh`.
- The [local AI agent](#local-ai-agent-goose) is the other heavy piece:
  its default model is an ~18 GB download and needs about 24 GB of RAM
  (GPU memory counts toward it). On smaller machines the model step is
  skipped with a warning; pick a smaller model in `config.sh`.

## Step 1 - Run the Automated Setup Script

The setup is split across `setup.sh`, `lib/` and `steps/` (see
[Project Layout](#project-layout)), so download the whole repository rather
than `setup.sh` alone. Open a terminal and run:

```bash
curl -fsSL https://github.com/diegochagas/linux-mint-setup/archive/refs/heads/main.tar.gz | tar -xz && cd linux-mint-setup-main && ./setup.sh
```

Or, with Git:

```bash
git clone https://github.com/diegochagas/linux-mint-setup.git && cd linux-mint-setup && ./setup.sh
```

To change any of the configurable values first, copy `config.sh.example` to
`config.sh` next to `setup.sh` and edit it before running the script.
`./setup.sh --dry-run` prints every action the script would take without
changing anything.

The script asks for the administrator password when it needs `sudo`
permissions. Keep an internet connection active while it runs. Each run
writes a log to the `logs/` folder.

## Step 2 - Manual Post-Install Steps

1. Configure automatic system snapshots:
   `Update Manager > Edit > System Snapshots > Wizard > Next > Next >
Weekly - Keep 4 > Next > Next > Finish`.
2. Open a new terminal and run `claude` once to sign in to Claude Code.
3. For Goose's Browser extension, install the Open Browser Control add-on
   in the browser Goose should control:
   [Firefox](https://addons.mozilla.org/firefox/addon/open-browser-control/)
   or [Chrome](https://chromewebstore.google.com/detail/open-browser-control/icicfjcgocaakibmmaejmoipckofnnpl).
4. Optional: to let Goose read email, add an IMAP account with
   `npx -p imap-mcp-server imap-setup`, then turn on the IMAP Email
   extension in Goose when you need it (see [Local AI Agent](#local-ai-agent-goose)).

## What `setup.sh` Does

The script stops if an unhandled command fails and performs the following
actions:

### System and APT Packages

- Removes Linux Mint's Snap restriction by renaming `nosnap.pref`, when present.
- Adds the official Sublime Text APT repository.
- Updates APT and installs:
  Firefox, ExifTool, VLC, Sublime Text, Git, Node.js, npm, Python 3, PyYAML, curl, jq, AntiMicroX,
  unrar, unzip, rsync, xclip, FreeRDP X11, libsecret-tools, CopyQ, btop, Inkscape,
  Nextcloud Desktop, FFmpeg, fontconfig, GParted, Tree, ShellCheck, Docker,
  Docker Compose, gh, nfs-kernel-server, zbar-tools, Anki, the TimGM6mb
  SoundFont, and supporting libraries.
- Configures Docker after installation by adding the current user to the
  `docker` group, fixing existing `~/.docker` ownership if needed, and enabling
  and starting the Docker and containerd systemd services. Log out and back in
  before using Docker without `sudo`.
- On AMD64 systems, installs Remote Mouse with its bundled green taskbar icon,
  starting it from its install directory (from the menu and at login) because
  the tray icon is loaded relative to the working directory, and the latest
  balenaEtcher release.
- On AMD64 and ARM64 systems, installs the latest `immich-go` release.
- On AMD64 systems, installs the pinned [Blender](https://www.blender.org/) LTS
  portable build to `/opt/blender` (linked as `/usr/local/bin/blender`).
- On AMD64 and ARM64 systems, installs the latest
  [LocalSend](https://localsend.org/) `.deb` release (not the Snap Store
  version — its AppArmor sandboxing breaks NetworkManager access and the
  system tray icon).
- On AMD64 and ARM64 systems, installs the latest
  [ZapFast](https://zapfast.rocks/) release as a user-local WhatsApp client.
  Its launcher uses the bundled SVG by absolute path so Cinnamon displays the
  ZapFast icon even before its user icon-theme cache is registered.
- On AMD64 systems, installs the latest [Scrcpy GUI](https://github.com/SimonAKing/scrcpy-gui)
  `.deb` release. Its official SHA-256 manifest is verified before installation;
  the package bundles compatible `scrcpy` and `adb` binaries.
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
- On AMD64 systems, installs Discord from Discord's official Linux `.deb`
  download.
- Installs [Hypnotix](https://github.com/linuxmint/hypnotix) from APT when it
  is not already available, then adds the IPTV-ORG Brazil M3U provider.

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
- OBS Studio
- Free Download Manager
- Dosage
- EasyRPG Player
- PPSSPP (PSP emulator)
- Telegram Desktop
- Surfshark

### Local AI Models (ComfyUI and Ollama)

The local AI models this machine's applications share live in their own
repository: [local-ai-setup](https://github.com/diegochagas/local-ai-setup).
The Local AI step clones it and runs its `setup.sh` every time (it is
idempotent: it skips what is there and resumes interrupted model
downloads), passing the `COMFYUI_*` and `OLLAMA_*` settings of this
`config.sh` through the environment.

- **ComfyUI** with open-weight image models (Qwen-Image-Edit, FLUX.2 klein,
  SAM 2.1, BiRefNet, LaMa), as the `comfyui` systemd user service, behind
  GIMPhoto's AI tools, comic-skills and photo-restore. **Skipped unless
  `COMFYUI_DIR` is set**, because the models are tens of GB (about 42 GB
  with the default `COMFYUI_MODEL_SETS`); needs an NVIDIA GPU.
- **Ollama**, the local language-model server, behind
  [Goose](#local-ai-agent-goose) (the steps after it), comic-skills,
  tvshow-skills and Digivice. `OLLAMA_MODELS_DIR` moves its models to
  another disk.

See the [local-ai-setup README](https://github.com/diegochagas/local-ai-setup#readme)
for the model sets, the service and the requirements. The repository can be
overridden with `LOCAL_AI_SETUP_REPO`.

### GIMPhoto

[GIMPhoto](https://github.com/diegochagas/gimphoto), GIMP with Photoshop's
tools and interface, is installed from the Flatpak bundle of its latest
GitHub release (`GIMPHOTO_RELEASES_API_URL`), after checking the SHA-256
GitHub records for it. It installs next to the official GIMP, with its own
app ID and user profile; Flatpak fetches the GNOME runtime it needs from
Flathub. Its AI tools run on the local ComfyUI above, which GIMPhoto starts
when it opens and stops when it closes. AMD64 only.

Once GIMPhoto is installed the step is skipped: to update it, install a
newer release's bundle (`flatpak install --user GIMPhoto.flatpak`).

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

### Git Config Includes

After the Homelab Backup step, the script adds each file listed in
`GIT_CONFIG_INCLUDES` in `config.sh` (comma separated) to the global Git
configuration with `git config --global --add include.path`. Use it for Git
settings that must not be committed anywhere, such as per-repository push URLs
kept in a folder synced by Nextcloud. Because the include lives in
`~/.gitconfig` rather than in a repository, it still applies after a project is
deleted and cloned again.

Git skips an include whose file does not exist yet, so the step can run before
Nextcloud has finished syncing: the settings take effect once the file arrives.
Paths already included are left alone, and an empty `GIT_CONFIG_INCLUDES` skips
the step.

A typical included file applies settings to one clone through `includeIf`:

```ini
[includeIf "gitdir:~/Projects/<repo>/"]
	path = <folder>/<repo>.gitconfig
```

and `<repo>.gitconfig` can, for example, push to GitHub and to a copy of the
repository on a home server:

```ini
[remote "origin"]
	pushurl = git@github.com:<user>/<repo>.git
	pushurl = <user>@<server>:<path-to-repo>
```

### Other Software

- Installs Tailscale using its official installation script.
- Installs [`immich-go`](https://github.com/simulot/immich-go) to
  `/usr/local/bin/immich-go` on AMD64 and ARM64 systems.
- Installs the [Blender](https://www.blender.org/download/lts/) LTS portable
  build pinned by `BLENDER_VERSION` / `BLENDER_TARBALL_URL` in `config.sh` to
  `/opt/blender`, links it as `/usr/local/bin/blender` and registers its menu
  entry. The `games-extractor` render pipeline drives it headless
  (`blender -b --python ...`); the apt package is older and the Snap build is
  sandboxed, which is why the official tarball is used.
- Installs [AppManager](https://github.com/kem-a/AppManager), then downloads the
  latest successful Wattage `build-appimage.yml` artifact for the current CPU
  architecture and installs the extracted AppImage with
  `app-manager install`.
- Installs [WinBoat](https://winboat.app/) on AMD64 systems by downloading the
  configured AppImage release and installing it with `app-manager install`.
- Installs [ZapFast](https://zapfast.rocks/) from its latest GitHub Linux
  release into `~/.local/lib/zapfast`, makes it available as
  `~/.local/bin/zapfast`, and creates a Cinnamon-compatible launcher with its
  bundled SVG icon.
- Installs [Claude Code](https://code.claude.com/docs/en/terminal-guide) using
  Anthropic's Linux terminal installer:
  ```bash
  curl -fsSL https://claude.ai/install.sh | bash
  ```
- Installs [Claude Desktop](https://claude.ai/download) on AMD64 systems by
  downloading Anthropic's latest x64 `.deb` installer and installing it with
  APT. The installer registers Anthropic's APT repository so Claude Desktop
  updates with the rest of the system packages.
- Installs [Discord](https://discord.com/download) on AMD64 systems from its
  official `.deb` download.
- Installs the latest Scrcpy GUI AMD64 `.deb` release after validating it
  against the upstream `SHA256SUMS.txt` manifest.

Installer and release source URLs, including the WinBoat AppImage URL, can also
be overridden in `config.sh`. See `config.sh.example` for the full list.

### Local AI Agent (Goose)

A free, open-source alternative to Claude Cowork that runs entirely on
this machine: [Goose](https://github.com/block/goose) as the agent and
[Ollama](https://ollama.com/) serving a local model.

- Ollama comes from the [Local AI step](#local-ai-models-comfyui-and-ollama)
  (local-ai-setup). It uses an NVIDIA GPU when the proprietary driver is
  installed (Driver Manager); a model larger than the GPU memory is split
  between GPU and CPU/RAM automatically.
- Installs the Goose CLI in `~/.local/bin` with Block's installer
  (AMD64 and ARM64) and, on AMD64, Goose Desktop from its latest `.deb`
  release after checking the SHA-256 GitHub records for it.
- Pulls the local model (`GOOSE_OLLAMA_BASE_MODEL`, by default
  Qwen3-30B-A3B-Instruct-2507, ~18 GB) and creates a copy named
  `GOOSE_OLLAMA_MODEL` with a 32k-token context. Ollama's default 4096
  tokens is too small: Goose's own instructions and tool descriptions
  take most of it.
- Writes Goose's `~/.config/goose/config.yaml`, keeping any existing
  settings (a previous version is saved as `config.yaml.bak`):
  - Ollama as the provider, with the model above.
  - Smart approval mode and a 50-turn limit, only when not set yet, so
    choices made later in Goose Desktop are kept. The limit stops a
    stuck task instead of letting it loop.
  - Extensions, each added only when missing:

    | Extension | What it does |
    | --- | --- |
    | Developer | Built in: runs shell commands and reads/edits files |
    | Browser | [Open Browser Control](https://www.npmjs.com/package/open-browser-control): controls your real Firefox or Chrome through its add-on ([manual step](#step-2---manual-post-install-steps)) |
    | SearXNG Search | [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng): web search through the SearXNG instance set in `GOOSE_SEARXNG_URL`; skipped when empty |
    | IMAP Email | [imap-mcp-server](https://www.npmjs.com/package/imap-mcp-server): reads and manages email. Added **disabled**: its 40 tools use a large part of a local model's context, so turn it on only for email tasks |

- Installs `steps/goose/goosehints` as `~/.config/goose/.goosehints`,
  rules Goose reads at the start of every session: report only facts
  it actually read, use the GitHub API instead of GitHub pages, read
  web pages with small `browser_execute_js` snippets instead of the
  whole DOM, and use `python3`.

Run `goose session` in a folder for the terminal version or open Goose
from the menu for the desktop app. What to expect from the default
model on a laptop with a 6 GB GPU: about 20 tokens/s, good at file,
shell, web search and simple browser tasks, weak at complex websites.
`browser_execute_js` is blocked on sites with a strict
Content-Security-Policy (GitHub, Gmail), and a small model may guess
instead of saying it could not read something, so check its facts.

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
- Configures Thunderbird to show the full content of every email: remote
  images and content load automatically and messages display as original
  HTML. The preferences go in the default profile's `user.js`; if there is no
  profile yet, open Thunderbird once and re-run `setup.sh`.
- Configures LocalSend to start automatically, minimized to the system tray.
- Installs the fonts from `steps/fonts/fonts` into
  `~/.local/share/fonts/linux-mint-setup` and refreshes the font cache with
  `fc-cache -f`.
- Installs the AntiMicroX controller profiles from
  `steps/antimicrox/profiles` into `~/.config/antimicrox/profiles`:
  ALendaDoHeroi, ApocalypseAcabouAPutaria, DragonBallZFighters, FallGuys,
  Jaspion, MegamanCollection, and SegaMegaDriveEGenesisClassics.
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
- Adds the files in `GIT_CONFIG_INCLUDES` to the global Git configuration.
- Configures Hypnotix with the `IPTV-ORG` M3U URL provider using the Brazilian
  playlist at `https://iptv-org.github.io/iptv/countries/br.m3u`. Existing
  providers are retained, and a prior `IPTV-ORG` entry is updated rather than
  duplicated.

## Project Layout

```text
setup.sh            Entry point: loads config.sh, lib/ and steps/, then runs
                    the steps in the order listed in run_setup_steps
config.sh.example   Template for the optional config.sh
lib/
  log.sh            Terminal output and the log file
  exec.sh           run (dry-run aware), downloads, file writes, temporary
                    directories and the error handler
  step.sh           run_step, skip_step, warn_step, require_architecture
                    and the summary
  system.sh         File, binary, user, systemd, PATH and autostart helpers
  packages.sh       APT, Snap, Flatpak, .deb and GitHub release helpers
  preflight.sh      Dependency, sudo, internet and OS checks
steps/              One setup step (install_* or configure_*) per file
  <name>.sh         A step without extra files
  <name>/<name>.sh  A step that ships files, kept in the same folder:
  antimicrox/       antimicrox.sh and the profiles/ it copies
  fonts/            fonts.sh and the fonts/ it installs
  goose/            goose.sh, goose-config.py (merges Goose's
                    config.yaml) and the goosehints it installs
  xcompose/         xcompose.sh and the XCompose rules it merges
```

Every step is a function that installs or configures one thing. It runs
inside `run_step`, which prints the step header and records the result in
the summary:

- Return normally and the step is recorded as installed/configured.
- Call `skip_step "reason"` when there is nothing to do (already installed,
  unsupported architecture, missing configuration).
- Call `warn_step "reason"` when the step could not complete but the setup
  should continue (a release asset is unavailable, a download failed).
- Use `require_architecture amd64 arm64 || return 0` to limit a step to some
  CPU architectures.

Every action that changes the system goes through `run`, `download_file`,
`run_remote_script`, `write_file`, `write_root_file` or `append_to_file`,
which print the action and skip it in `--dry-run` mode. Any command that
fails aborts the setup and reports its file and line.

Values that can be overridden in `config.sh` are declared with
`: "${NAME:=default}"` at the top of the step that uses them, and listed in
`config.sh.example`.

To add a step, create `steps/<name>.sh` with its function, `source` it in
`setup.sh` and add a `run_step` line to `run_setup_steps` in the position
where it should run. If the step ships files (fonts, profiles, config
snippets), put it in `steps/<name>/<name>.sh` with the files beside it and
resolve them from `${BASH_SOURCE[0]%/*}`, as the fonts step does.

## Notes

### GIMPhoto and the official GIMP

- GIMPhoto replaces the official GIMP and its
  [gimp-setup](https://github.com/diegochagas/gimp-setup) add-ons, which
  this setup no longer installs. To add Photoshop-style plug-ins to the
  official GIMP instead, run gimp-setup on its own; its AI plug-ins use the
  same local ComfyUI.
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
- Blender is installed only on AMD64 systems (the official portable build has
  no ARM64 Linux release).
- LocalSend is installed only on AMD64 and ARM64 systems, from its official
  `.deb` release rather than the Snap Store, and any existing Snap install is
  removed first.
- Scrcpy GUI is installed only on AMD64 systems from its official `.deb` release.
  The release bundle includes `scrcpy` and `adb`; enable USB debugging on an
  Android device before connecting it.
- AppManager and Wattage are installed only on AMD64 and ARM64 systems. WinBoat
  is installed only on AMD64 systems. If a configured AppImage or nightly
  artifact is temporarily unavailable, the script reports that in the summary
  and continues.
- Claude Code is installed with Anthropic's terminal installer. Run `claude`
  once after setup to sign in.
- Claude Desktop is installed only on AMD64 systems.
- Goose Desktop is installed only on AMD64 systems; Ollama (through
  local-ai-setup) and the Goose CLI on AMD64 and ARM64. The Goose Desktop package adds
  `/usr/bin/goose` as a link to the desktop app, so the setup keeps
  `~/.local/bin` first on the `PATH` and `goose` still runs the CLI.
- Hypnotix is installed from APT when missing. Its `IPTV-ORG` provider uses the
  public Brazilian playlist maintained by IPTV-ORG.
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
