#!/bin/bash
#
# Omakub — Microsoft/.NET Enterprise Edition
# Single idempotent install script for Ubuntu 24.04+ LTS
# Installs: Edge, VS Code, .NET SDK, Intune, MDE, YubiKey, Docker,
#           Alacritty + Tokyo Night theme, GNOME desktop tweaks
#
# Run: curl -sL https://raw.githubusercontent.com/YOUR_ORG/omakub/main/setup.sh | bash
# Or:  bash setup.sh
#
# Fully idempotent — safe to re-run at any time.
#

set -e
trap 'echo ""; echo "❌ Setup failed! Re-run this script to retry."; exit 1' ERR

OMAKUB_PATH="$HOME/.local/share/omakub"

# ─── Preflight ────────────────────────────────────────────────────────────────

echo '
________                  __        ___.
\_____  \   _____ _____  |  | ____ _\_ |__
 /   |   \ /     \\__   \ |  |/ /  |  \ __ \
/    |    \  Y Y  \/ __ \|    <|  |  / \_\ \
\_______  /__|_|  (____  /__|_ \____/|___  /
        \/      \/     \/     \/         \/

        Microsoft/.NET Enterprise Edition
'

if [ ! -f /etc/os-release ]; then
  echo "Error: Unable to determine OS." && exit 1
fi
. /etc/os-release
if [ "$ID" != "ubuntu" ] || [ "$(echo "$VERSION_ID >= 24.04" | bc)" != 1 ]; then
  echo "Error: Requires Ubuntu 24.04+. You have: $ID $VERSION_ID" && exit 1
fi
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "i686" ]; then
  echo "Error: Requires x86_64. You have: $ARCH" && exit 1
fi

echo "✓ Ubuntu $VERSION_ID on $ARCH"

# ─── Prevent sleep during install (GNOME only) ───────────────────────────────

IS_GNOME=false
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
  IS_GNOME=true
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.desktop.session idle-delay 0
fi

# ─── Core packages ────────────────────────────────────────────────────────────

echo ""
echo "▶ Installing core packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y \
  curl git unzip wget gpg bc lsb-release apt-transport-https ca-certificates \
  build-essential pkg-config autoconf libssl-dev zlib1g-dev \
  sqlite3 libsqlite3-0 python3 python3-pip \
  fzf ripgrep bat eza zoxide plocate fd-find wl-clipboard

# ─── Microsoft signing keys & repos (idempotent) ─────────────────────────────

echo ""
echo "▶ Configuring Microsoft package repositories..."

# Microsoft GPG key for Ubuntu 24.04+ (official: microsoft-prod.gpg)
if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
  curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-prod.gpg > /dev/null
  sudo chmod o+r /usr/share/keyrings/microsoft-prod.gpg
fi

# VS Code repo
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
  if [ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]; then
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm -f /tmp/packages.microsoft.gpg
  fi
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
fi

# Edge repo (with signed-by for proper security)
if [ ! -f /etc/apt/sources.list.d/microsoft-edge.list ]; then
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
    | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
  # Edge-specific key in keyrings (official recommendation)
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
fi

# Microsoft prod repo — official method: download prod.list from Microsoft's config endpoint
# (used by Intune, Identity Broker, .NET SDK, MDE/mdatp)
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
  curl -sSL "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list" \
    | sudo tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null
fi

# Microsoft insiders-fast repo (optional — for early MDE/Intune updates)
FAST_LIST="/etc/apt/sources.list.d/microsoft-ubuntu-$(lsb_release -cs)-insiders-fast.list"
if [ ! -f "$FAST_LIST" ]; then
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod insiders-fast main" \
    | sudo tee "$FAST_LIST" > /dev/null
fi

sudo apt update -y

# ─── Microsoft Edge ───────────────────────────────────────────────────────────

echo ""
echo "▶ Installing Microsoft Edge..."
sudo apt install -y microsoft-edge-stable
xdg-settings set default-web-browser microsoft-edge.desktop 2>/dev/null || true

# ─── Visual Studio Code ──────────────────────────────────────────────────────

echo ""
echo "▶ Installing Visual Studio Code..."
sudo apt install -y code

mkdir -p ~/.config/Code/User
if [ -f "$OMAKUB_PATH/configs/vscode.json" ]; then
  cp "$OMAKUB_PATH/configs/vscode.json" ~/.config/Code/User/settings.json
fi

# Install Tokyo Night theme (idempotent — extension install is a no-op if present)
code --install-extension enkia.tokyo-night 2>/dev/null || true

# ─── .NET SDK ─────────────────────────────────────────────────────────────────

echo ""
echo "▶ Installing .NET SDK..."
sudo apt-get install -y dotnet-sdk-10.0 aspnetcore-runtime-10.0
echo "  .NET $(dotnet --version) installed"

# ─── Microsoft Identity Broker + Intune ───────────────────────────────────────

echo ""
echo "▶ Installing Microsoft Identity Broker & Intune Portal..."
sudo apt install -y microsoft-identity-broker
sudo apt install -y intune-portal

# ─── Microsoft Defender for Endpoint ──────────────────────────────────────────
# Official: https://learn.microsoft.com/en-us/defender-endpoint/linux-install-manually

echo ""
echo "▶ Installing Microsoft Defender for Endpoint (MDE)..."
sudo apt install -y curl libplist-utils
sudo apt install -y mdatp || echo "  ⚠ mdatp package not available — check repo config"

# Verify MDE installation
if command -v mdatp &>/dev/null; then
  echo "  ✓ mdatp installed"
  echo ""
  echo "  ── MDE Post-Install Steps ──"
  echo "  1. Download the MDE onboarding package from Defender portal"
  echo "  2. unzip WindowsDefenderATPOnboardingPackage.zip"
  echo "  3. sudo python3 MicrosoftDefenderATPOnboardingLinuxServer.py"
  echo "  4. Verify: mdatp health  (healthy=true, licensed=true, releaseRing=Production)"
  echo "  5. Test connectivity: mdatp connectivity test"
  echo "  6. Update: sudo apt-get install --only-upgrade mdatp"
  echo ""
else
  echo "  ⚠ mdatp not found — onboarding will need to be done after manual install"
fi

# ─── YubiKey Smart Card ──────────────────────────────────────────────────────

echo ""
echo "▶ Setting up YubiKey Smart Card..."
sudo apt install -y pcscd yubikey-manager opensc libnss3-tools openssl

mkdir -p "$HOME/.pki/nssdb"
chmod 700 "$HOME/.pki"
chmod 700 "$HOME/.pki/nssdb"

# Initialize NSS DB (idempotent — -force overwrites safely)
modutil -force -create -dbdir "sql:$HOME/.pki/nssdb" 2>/dev/null || true

# Register OpenSC PKCS#11 module (idempotent — -force replaces if exists)
modutil -force -dbdir "sql:$HOME/.pki/nssdb" -add 'SC Module' \
  -libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so 2>/dev/null || true

# ─── Docker ───────────────────────────────────────────────────────────────────

echo ""
echo "▶ Installing Docker..."
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo wget -qO /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
fi
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo usermod -aG docker "${USER}" 2>/dev/null || true

# Docker log rotation
echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"5"}}' | sudo tee /etc/docker/daemon.json > /dev/null

# ─── GitHub CLI ───────────────────────────────────────────────────────────────

echo ""
echo "▶ Installing GitHub CLI..."
if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
fi
sudo apt install -y gh

# ─── Terminal tools (latest releases) ─────────────────────────────────────────

echo ""
echo "▶ Installing terminal tools..."

# btop
sudo apt install -y btop

# fastfetch
if ! command -v fastfetch &>/dev/null; then
  sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
  sudo apt update -y
fi
sudo apt install -y fastfetch

# lazygit (latest GitHub release)
echo "  lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
if [ -n "$LAZYGIT_VERSION" ]; then
  curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
  rm -f /tmp/lazygit.tar.gz /tmp/lazygit
fi
mkdir -p ~/.config/lazygit && touch ~/.config/lazygit/config.yml

# lazydocker (latest GitHub release)
echo "  lazydocker..."
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
if [ -n "$LAZYDOCKER_VERSION" ]; then
  curl -sLo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
  tar -xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
  sudo install /tmp/lazydocker /usr/local/bin
  rm -f /tmp/lazydocker.tar.gz /tmp/lazydocker
fi

# zellij (latest GitHub release)
echo "  zellij..."
curl -sLo /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
tar -xf /tmp/zellij.tar.gz -C /tmp zellij
sudo install /tmp/zellij /usr/local/bin
rm -f /tmp/zellij.tar.gz /tmp/zellij

# gum (official Charmbracelet apt repo — always latest)
echo "  gum..."
if [ ! -f /etc/apt/sources.list.d/charm.list ]; then
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
    | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
  sudo apt update
fi
sudo apt install -y gum

# ─── Git config ───────────────────────────────────────────────────────────────

echo ""
echo "▶ Configuring git..."
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global pull.rebase true

# Only prompt for name/email if not already set
if [ -z "$(git config --global user.name)" ]; then
  if command -v gum &>/dev/null; then
    SYSTEM_NAME=$(getent passwd "$USER" | cut -d ':' -f 5 | cut -d ',' -f 1)
    GIT_NAME=$(gum input --placeholder "Enter full name" --value "$SYSTEM_NAME" --prompt "Name> ")
    [ -n "$GIT_NAME" ] && git config --global user.name "$GIT_NAME"
  fi
fi
if [ -z "$(git config --global user.email)" ]; then
  if command -v gum &>/dev/null; then
    GIT_EMAIL=$(gum input --placeholder "Enter email address" --prompt "Email> ")
    [ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
  fi
fi

# ─── GNOME Desktop (only if running GNOME) ───────────────────────────────────

if [ "$IS_GNOME" = true ]; then
  echo ""
  echo "▶ Configuring GNOME desktop..."

  # Flatpak
  sudo apt install -y flatpak gnome-software-plugin-flatpak
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  # GNOME desktop tools
  sudo apt install -y gnome-sushi gnome-tweak-tool flameshot vlc

  # ── Fonts ──
  echo "  Fonts..."
  mkdir -p ~/.local/share/fonts
  if ! fc-list | grep -qi "CaskaydiaMono"; then
    curl -sLo /tmp/CascadiaMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"
    unzip -qo /tmp/CascadiaMono.zip -d /tmp/CascadiaFont
    cp /tmp/CascadiaFont/*.ttf ~/.local/share/fonts/
    rm -rf /tmp/CascadiaMono.zip /tmp/CascadiaFont
  fi
  if ! fc-list | grep -qi "iAWriterMono"; then
    curl -sLo /tmp/iafonts.zip "https://github.com/iaolo/iA-Fonts/archive/refs/heads/master.zip"
    unzip -qo /tmp/iafonts.zip -d /tmp/iaFonts
    cp /tmp/iaFonts/iA-Fonts-master/iA\ Writer\ Mono/Static/iAWriterMonoS-*.ttf ~/.local/share/fonts/
    rm -rf /tmp/iafonts.zip /tmp/iaFonts
  fi
  fc-cache -f

  # ── Alacritty + Tokyo Night ──
  echo "  Alacritty..."
  sudo apt install -y alacritty
  mkdir -p ~/.config/alacritty
  if [ -d "$OMAKUB_PATH" ]; then
    cp "$OMAKUB_PATH/configs/alacritty.toml" ~/.config/alacritty/alacritty.toml
    cp "$OMAKUB_PATH/configs/alacritty/shared.toml" ~/.config/alacritty/shared.toml
    cp "$OMAKUB_PATH/configs/alacritty/pane.toml" ~/.config/alacritty/pane.toml
    cp "$OMAKUB_PATH/configs/alacritty/btop.toml" ~/.config/alacritty/btop.toml
    cp "$OMAKUB_PATH/themes/tokyo-night/alacritty.toml" ~/.config/alacritty/theme.toml
    cp "$OMAKUB_PATH/configs/alacritty/fonts/CaskaydiaMono.toml" ~/.config/alacritty/font.toml
    cp "$OMAKUB_PATH/configs/alacritty/font-size.toml" ~/.config/alacritty/font-size.toml
    alacritty migrate 2>/dev/null || true
    alacritty migrate -c ~/.config/alacritty/pane.toml 2>/dev/null || true
    alacritty migrate -c ~/.config/alacritty/btop.toml 2>/dev/null || true
  fi
  sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty 2>/dev/null || true

  # ── Zellij config ──
  mkdir -p ~/.config/zellij/themes
  if [ -d "$OMAKUB_PATH" ]; then
    [ ! -f "$HOME/.config/zellij/config.kdl" ] && cp "$OMAKUB_PATH/configs/zellij.kdl" ~/.config/zellij/config.kdl
    cp "$OMAKUB_PATH/themes/tokyo-night/zellij.kdl" ~/.config/zellij/themes/tokyo-night.kdl
  fi

  # ── btop config + Tokyo Night theme ──
  mkdir -p ~/.config/btop/themes
  if [ -d "$OMAKUB_PATH" ]; then
    cp "$OMAKUB_PATH/configs/btop.conf" ~/.config/btop/btop.conf
    cp "$OMAKUB_PATH/themes/tokyo-night/btop.theme" ~/.config/btop/themes/tokyo-night.theme
  fi

  # ── fastfetch config ──
  if [ ! -f "$HOME/.config/fastfetch/config.jsonc" ] && [ -d "$OMAKUB_PATH" ]; then
    mkdir -p ~/.config/fastfetch
    cp "$OMAKUB_PATH/configs/fastfetch.jsonc" ~/.config/fastfetch/config.jsonc
  fi

  # ── Shell config ──
  echo "  Shell..."
  [ -f ~/.bashrc ] && [ ! -f ~/.bashrc.pre-omakub ] && cp ~/.bashrc ~/.bashrc.pre-omakub
  if [ -d "$OMAKUB_PATH" ]; then
    cp "$OMAKUB_PATH/configs/bashrc" ~/.bashrc
    [ -f "$OMAKUB_PATH/configs/inputrc" ] && cp "$OMAKUB_PATH/configs/inputrc" ~/.inputrc
  fi

  # ── GNOME extensions ──
  echo "  GNOME extensions..."
  sudo apt install -y gnome-shell-extension-manager gir1.2-gtop-2.0 gir1.2-clutter-1.0
  pipx install gnome-extensions-cli --system-site-packages 2>/dev/null || true

  # Disable default Ubuntu extensions (safe if already disabled)
  gnome-extensions disable tiling-assistant@ubuntu.com 2>/dev/null || true
  gnome-extensions disable ubuntu-appindicators@ubuntu.com 2>/dev/null || true
  gnome-extensions disable ubuntu-dock@ubuntu.com 2>/dev/null || true
  gnome-extensions disable ding@rastersoft.com 2>/dev/null || true

  # Install extensions (gext install is idempotent)
  echo "  Installing GNOME extensions (you may need to confirm prompts)..."
  gext install tactile@lundal.io 2>/dev/null || true
  gext install just-perfection-desktop@just-perfection 2>/dev/null || true
  gext install blur-my-shell@aunetx 2>/dev/null || true
  gext install space-bar@luchrioh 2>/dev/null || true
  gext install undecorate@sun.wxg@gmail.com 2>/dev/null || true
  gext install tophat@fflewddur.github.io 2>/dev/null || true
  gext install AlphabeticalAppGrid@stuarthayhurst 2>/dev/null || true

  # Compile schemas
  for ext in tactile@lundal.io just-perfection-desktop@just-perfection blur-my-shell@aunetx space-bar@luchrioh tophat@fflewddur.github.io AlphabeticalAppGrid@stuarthayhurst; do
    SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/$ext/schemas"
    if [ -d "$SCHEMA_DIR" ]; then
      for schema in "$SCHEMA_DIR"/*.gschema.xml; do
        [ -f "$schema" ] && sudo cp "$schema" /usr/share/glib-2.0/schemas/
      done
    fi
  done
  sudo glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true

  # ── Configure extensions ──
  echo "  Configuring extensions..."

  # Tactile
  gsettings set org.gnome.shell.extensions.tactile col-0 1 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tactile col-1 2 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tactile col-2 1 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tactile col-3 0 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tactile row-0 1 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tactile row-1 1 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tactile gap-size 32 2>/dev/null || true

  # Just Perfection
  gsettings set org.gnome.shell.extensions.just-perfection animation 2 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.just-perfection dash-app-running true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.just-perfection workspace true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.just-perfection workspace-popup false 2>/dev/null || true

  # Blur My Shell
  gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder blur false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.lockscreen blur false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.screenshot blur false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.window-list blur false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.overview blur true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.overview pipeline 'pipeline_default' 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock brightness 0.6 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock sigma 30 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock style-dash-to-dock 0 2>/dev/null || true

  # Space Bar
  gsettings set org.gnome.shell.extensions.space-bar.behavior smart-workspace-names false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-activate-workspace-shortcuts false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.space-bar.shortcuts enable-move-to-workspace-shortcuts true 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.space-bar.shortcuts open-menu "@as []" 2>/dev/null || true

  # TopHat (Tokyo Night color)
  gsettings set org.gnome.shell.extensions.tophat show-icons false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tophat show-cpu false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tophat show-disk false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tophat show-mem false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tophat show-fs false 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tophat network-usage-unit bits 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.tophat meter-fg-color "#924d8b" 2>/dev/null || true

  # AlphabeticalAppGrid
  gsettings set org.gnome.shell.extensions.alphabetical-app-grid folder-order-position 'end' 2>/dev/null || true

  # ── GNOME settings ──
  echo "  GNOME settings..."
  gsettings set org.gnome.mutter center-new-windows true
  gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaMono Nerd Font 10'
  gsettings set org.gnome.desktop.calendar show-weekdate true
  gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

  # ── GNOME theme (Tokyo Night) ──
  echo "  Tokyo Night theme..."
  if [ -d "$OMAKUB_PATH" ]; then
    source "$OMAKUB_PATH/themes/tokyo-night/gnome.sh" 2>/dev/null || true
  fi

  # ── GNOME hotkeys ──
  echo "  Hotkeys..."
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
  gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
  gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys next "['<Shift>AudioPlay']"
  gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"

  # 6 fixed workspaces
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

  # Alt for pinned dock apps
  for i in $(seq 1 9); do
    gsettings set org.gnome.shell.keybindings switch-to-application-$i "['<Alt>$i']"
  done

  # Super for workspaces
  for i in $(seq 1 6); do
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
  done

  # Custom keybindings
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"

  # Flameshot on Ctrl+Print
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Flameshot'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'sh -c -- "flameshot gui"'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Control>Print'

  # New Alacritty window on Shift+Alt+2
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'New Alacritty Window'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'alacritty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Shift><Alt>2'

  # New Edge window on Shift+Alt+1
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'New Edge Window'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'microsoft-edge --new-window'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Shift><Alt>1'

  # New VS Code window on Shift+Alt+3
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'New VS Code Window'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'code --new-window'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Shift><Alt>3'

  # ── XCompose ──
  if [ -d "$OMAKUB_PATH" ]; then
    export OMAKUB_USER_NAME="$(git config --global user.name)"
    export OMAKUB_USER_EMAIL="$(git config --global user.email)"
    envsubst < "$OMAKUB_PATH/configs/xcompose" > ~/.XCompose 2>/dev/null || true
    ibus restart 2>/dev/null || true
    gsettings set org.gnome.desktop.input-sources xkb-options "['compose:caps']" 2>/dev/null || true
  fi

  # ── App grid cleanup ──
  echo "  App grid..."
  sudo rm -f /usr/share/applications/btop.desktop
  sudo rm -f /usr/share/applications/org.flameshot.Flameshot.desktop
  sudo rm -f /usr/share/applications/display-im6.q16.desktop
  sudo rm -f /usr/share/applications/display-im7.q16.desktop
  sudo rm -f /usr/share/applications/org.gnome.SystemMonitor.desktop

  gsettings set org.gnome.desktop.app-folders folder-children "['Utilities', 'Sundry', 'YaST', 'Updates', 'Xtra']"
  gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Updates/ name 'Install & Update'
  gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Updates/ apps \
    "['org.gnome.Software.desktop', 'software-properties-drivers.desktop', 'software-properties-gtk.desktop', 'update-manager.desktop', 'firmware-updater_firmware-updater.desktop', 'snap-store_snap-store.desktop']"
  gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Xtra/ name 'Xtra'
  gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Xtra/ apps \
    "['org.Characters.desktop', 'gnome-language-selector.desktop', 'org.gnome.PowerStats.desktop', 'org.gnome.Logs.desktop', 'yelp.desktop', 'org.gnome.Yelp.desktop', 'org.gnome.eog.desktop', 'org.gnome.Sysprof.desktop']"

  # ── Desktop launchers ──
  echo "  Desktop launchers..."
  mkdir -p ~/.local/share/applications

  cat <<EOF > ~/.local/share/applications/About.desktop
[Desktop Entry]
Version=1.0
Name=About
Comment=System information from Fastfetch
Exec=alacritty --config-file /home/$USER/.config/alacritty/pane.toml --class=About --title=About -e bash -c 'fastfetch; read -n 1 -s'
Terminal=false
Type=Application
Icon=/home/$USER/.local/share/omakub/applications/icons/Ubuntu.png
Categories=GTK;
StartupNotify=false
EOF

  cat <<EOF > ~/.local/share/applications/Activity.desktop
[Desktop Entry]
Version=1.0
Name=Activity
Comment=System activity from btop
Exec=alacritty --config-file /home/$USER/.config/alacritty/btop.toml --class=Activity --title=Activity -e btop
Terminal=false
Type=Application
Icon=/home/$USER/.local/share/omakub/applications/icons/Activity.png
Categories=GTK;
StartupNotify=false
EOF

  cat <<EOF > ~/.local/share/applications/Docker.desktop
[Desktop Entry]
Version=1.0
Name=Docker
Comment=Manage Docker containers with LazyDocker
Exec=alacritty --config-file /home/$USER/.config/alacritty/pane.toml --class=Docker --title=Docker -e lazydocker
Terminal=false
Type=Application
Icon=/home/$USER/.local/share/omakub/applications/icons/Docker.png
Categories=GTK;
StartupNotify=false
EOF

  # ── Dock favorites ──
  echo "  Dock..."
  DOCK_APPS=(
    "microsoft-edge.desktop"
    "Alacritty.desktop"
    "code.desktop"
    "Activity.desktop"
    "Docker.desktop"
    "org.gnome.Settings.desktop"
    "org.gnome.Nautilus.desktop"
  )

  installed_apps=()
  desktop_dirs=(
    "/var/lib/flatpak/exports/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
    "$HOME/.local/share/applications"
  )
  for app in "${DOCK_APPS[@]}"; do
    for dir in "${desktop_dirs[@]}"; do
      if [ -f "$dir/$app" ]; then
        installed_apps+=("$app")
        break
      fi
    done
  done
  favorites_list=$(printf "'%s'," "${installed_apps[@]}")
  favorites_list="[${favorites_list%,}]"
  gsettings set org.gnome.shell favorite-apps "$favorites_list"

  # ── Framework laptop tweaks ──
  COMPUTER_MAKER=$(sudo dmidecode -t system 2>/dev/null | grep 'Manufacturer:' | awk '{print $2}')
  SCREEN_RESOLUTION=$(xrandr 2>/dev/null | grep '*+' | awk '{print $1}')
  if [ "$COMPUTER_MAKER" = "Framework" ] && [ "$SCREEN_RESOLUTION" = "2256x1504" ]; then
    gsettings set org.gnome.desktop.interface text-scaling-factor 0.8
    gsettings set org.gnome.desktop.interface cursor-size 16
    sed -i "s/size = 9/size = 7/g" ~/.config/alacritty/font-size.toml
  fi

  # Restore normal idle/lock
  gsettings set org.gnome.desktop.screensaver lock-enabled true
  gsettings set org.gnome.desktop.session idle-delay 300
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Setup complete!"
echo ""
echo "  Installed:"
echo "    • Microsoft Edge (default browser)"
echo "    • Visual Studio Code + Tokyo Night"
echo "    • .NET SDK $(dotnet --version 2>/dev/null || echo '10.0')"
echo "    • Microsoft Intune Portal"
echo "    • Microsoft Defender for Endpoint"
echo "    • YubiKey Smart Card (pcscd + OpenSC)"
echo "    • Docker Engine"
echo "    • GitHub CLI"
echo "    • Alacritty + Zellij + Tokyo Night"
echo ""
echo "  Next steps:"
echo "    1. Reboot: sudo reboot"
echo "    2. Open Intune app → sign in with work account"
echo "    3. Open Edge → sign in with work account"
echo "    4. MDE onboarding (if required):"
echo "       unzip WindowsDefenderATPOnboardingPackage.zip"
echo "       sudo python3 MicrosoftDefenderATPOnboardingLinuxServer.py"
echo "       mdatp health"
echo "    5. YubiKey: insert key → ykman info"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v gum &>/dev/null; then
  gum confirm "Ready to reboot now?" && sudo reboot || echo "Reboot when ready: sudo reboot"
fi
