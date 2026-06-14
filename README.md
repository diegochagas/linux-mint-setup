# Linux Mint Setup

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

1. Install the GIMP plugins described in the
   [DioLinux guide](https://diolinux.com.br/design/como-instalar-plugins-no-gimp.html).
2. Install Claude Desktop for Linux by following the instructions in the
   [claude-desktop-debian repository](https://github.com/aaddrick/claude-desktop-debian).
3. Install the fonts located in the `Softwares` folder.
4. Configure automatic system snapshots:
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
  unzip, xclip, CopyQ, btop, Flameshot, Inkscape, and supporting libraries.
- On AMD64 systems, installs Remote Mouse and the latest balenaEtcher release.

### Snap Applications

The script installs Snap support and then installs:

- Surfshark
- GIMP
- Franz
- Visual Studio Code
- Insomnia
- LocalSend

### Flatpak Applications

The script installs Flatpak, adds Flathub, and installs:

- NormCap
- Google Chrome
- EmojiMart
- Mimick

### Other Software

- Installs Tailscale using its official installation script.
- Installs DaVinci Resolve when its installer is found at the path described in
  Step 1.
- Moves selected bundled DaVinci Resolve libraries into
  `/opt/resolve/libs/oldlibs` to improve compatibility with Linux Mint.

### Desktop Configuration

The script creates these Cinnamon keyboard shortcuts:

| Shortcut | Action |
| --- | --- |
| `Ctrl + Super + S` | Open Flameshot |
| `Super + V` | Toggle CopyQ |
| `Ctrl + Shift + S` | Open NormCap |
| `Ctrl + Shift + Space` | Open EmojiMart |

It also:

- Configures CopyQ to start automatically.
- Allows unverified Flatpak applications to appear in Software Manager.
- Enables automatic update checks and updates in Update Manager.

## Notes

- Remote Mouse and balenaEtcher are installed only on AMD64 systems.
- The script downloads software and runs official third-party installation
  scripts, so review `setup.sh` before running it.
- Some operations may already be complete when the script is run again. Review
  any errors before retrying.
- Type the cedilla character (`ç`) with `AltGr + ,` (comma).
