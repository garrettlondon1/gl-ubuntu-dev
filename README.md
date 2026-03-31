# Omakub — Microsoft/.NET Enterprise Edition

An opinionated Ubuntu 24.04+ setup for Microsoft enterprise development. One script, fully idempotent.

## What it installs

| Category | Packages |
|---|---|
| **Browser** | Microsoft Edge (default) |
| **Editor** | Visual Studio Code + Tokyo Night theme |
| **Runtime** | .NET SDK 9.0 + ASP.NET Core Runtime |
| **Enterprise** | Intune Portal, Microsoft Identity Broker, Microsoft Defender for Endpoint |
| **Security** | YubiKey Smart Card (pcscd, OpenSC, NSS DB, PKCS#11) |
| **Containers** | Docker Engine + Compose + LazyDocker |
| **Terminal** | Alacritty + Zellij + Tokyo Night, btop, fastfetch |
| **CLI Tools** | fzf, ripgrep, bat, eza, zoxide, fd, lazygit, GitHub CLI, gum |
| **Desktop** | GNOME extensions (Tactile, Just Perfection, Blur My Shell, Space Bar, TopHat), Flatpak, Flameshot, VLC |
| **Fonts** | Cascadia Mono Nerd Font, iA Writer Mono |

## Quick install

```bash
bash setup.sh
```

Or bootstrap from scratch on a fresh Ubuntu 24.04+ box:

```bash
bash boot.sh
```

## Idempotent

Safe to re-run at any time. Every step checks before acting:
- Repos are only added if not already present
- Packages use `apt install -y` (no-op if installed)
- Configs are overwritten to ensure consistency
- Git identity is only prompted if not already set

## After install

1. **Reboot**: `sudo reboot`
2. **Intune**: Open the Intune app → sign in with your work account
3. **Edge**: Open Edge → sign in with your work account
4. **MDE onboarding** (if required by your org):
   ```bash
   unzip WindowsDefenderATPOnboardingPackage.zip
   sudo python3 MicrosoftDefenderATPOnboardingLinuxServer.py
   mdatp health
   ```
5. **YubiKey**: Insert your key → `ykman info`

## Customization

Run `omakub` in the terminal for the interactive menu:
- **Theme**: Switch between Tokyo Night, Catppuccin, Nord, and more
- **Font**: Change programming font (Cascadia Mono, Fira Mono, JetBrains Mono, Meslo)
- **Update**: Update lazygit, lazydocker, zellij to latest

## Shell aliases

```bash
# .NET
dn    → dotnet
dnr   → dotnet run
dnb   → dotnet build
dnt   → dotnet test
dnw   → dotnet watch
dnn   → dotnet new
dnef  → dotnet ef

# Tools
g → git  |  d → docker  |  lzg → lazygit  |  lzd → lazydocker
```

## Based on

[Omakub](https://github.com/basecamp/omakub) by Basecamp — stripped down and rebuilt for Microsoft enterprise use.

Turn a fresh Ubuntu installation into a fully-configured, beautiful, and modern web development system by running a single command. That's the one-line pitch for Omakub. No need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools. Omakub is an opinionated take on what Linux can be at its best.

Watch the introduction video and read more at [omakub.org](https://omakub.org).

## Contributing to the documentation

Please help us improve Omakub's documentation on the [basecamp/omakub-site repository](https://github.com/basecamp/omakub-site).

## License

Omakub is released under the [MIT License](https://opensource.org/licenses/MIT).

## Extras

While omakub is purposed to be an opinionated take, the open source community offers alternative customization, add-ons, extras, that you can use to adjust, replace or enrich your experience.

[⇒ Browse the omakub extensions.](EXTENSIONS.md)
