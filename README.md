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
- Franz
- Visual Studio Code
- Insomnia
- LocalSend

### Flatpak Applications

The script installs Flatpak, adds Flathub, and installs:

- [GIMP](https://www.gimp.org)
- [G'MIC-Qt plug-in for GIMP 3](https://github.com/flathub/org.gimp.GIMP.Plugin.GMic)
- NormCap
- Google Chrome
- Emojify
- Mimick

### GIMP AI Remove Background Plug-in

The script also installs the
[AI Remove Background for GIMP 3](https://github.com/galixstroyer/ai-remove-background-g3)
plug-in:

- Installs `rembg` and `onnxruntime` inside the Flatpak GIMP Python environment.
- Patches the plug-in to use Flatpak's Python and its installed packages.
- Installs the plug-in for Flatpak GIMP 3.2 and the GIMP 3.2/3.0 user config
  directories.
- Grants Flatpak GIMP access to the home directory so the plug-in can process
  files there.

After restarting GIMP, use the plug-in from
`Filters > AI > AI Remove Background`. Its first run downloads an AI model of
approximately 176 MB.

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
| `Alt + S` | Open Flameshot |
| `Alt + V` | Toggle CopyQ |
| `Alt + T` | Open NormCap |
| `Alt + E` | Open Emojify |

It also:

- Configures CopyQ to start automatically.
- Allows unverified Flatpak applications to appear in Software Manager.
- Enables automatic update checks and updates in Update Manager.

## Notes

- Remote Mouse and balenaEtcher are installed only on AMD64 systems.
- The AI Remove Background installation patches the current upstream plug-in.
  If its code structure changes, the setup stops instead of installing a
  potentially broken patch.
- Flatpak GIMP receives access to the entire home directory through
  `flatpak override --user org.gimp.GIMP --filesystem=home`.
- The script downloads software and runs official third-party installation
  scripts, so review `setup.sh` before running it.
- Some operations may already be complete when the script is run again. Review
  any errors before retrying.
- Type the cedilla character (`ç`) with `AltGr + ,` (comma).
