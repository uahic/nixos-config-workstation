# NixOS Config for my primary AI-Development/Gaming Workstation

## Packages

### System Tools
- `wget`, `curl` — network utilities
- `git` — version control
- `vim` + `vim-nix` — editor
- `htop`, `iotop` — system monitoring
- `tree` — directory listing
- `stow` — dotfile management
- `mtr` — network monitoring
- `alejandra` — Nix formatter
- `pre-commit` — Git hooks

### Desktop & GUI
- GNOME — desktop environment (with GDM)
- `terminator` — terminal emulator
- `librewolf` — Firefox-based privacy browser (uBlock Origin, DuckDuckGo)
- `gimp` — image editor
- `mupdf` — PDF viewer
- `libreoffice` — office suite
- `evolution` — email client
- `obsidian` — markdown notes
- `vscode-fhs` — Visual Studio Code
- GNOME extensions: AppIndicator, Dash to Dock
- `ckb-next` — Corsair keyboard/mouse driver
- Flatpak support

### Audio
- PipeWire (with ALSA, PulseAudio, JACK compatibility)

### Music Composition Software
- `muse-sounds-manager` — MuseScore sounds

### Gaming
- Steam (with Proton GE)
- `lutris` — game manager
- `protonup-qt` — Proton version manager
- `protontricks`, `winetricks`, `wine` — Windows compatibility
- `nvtop` — GPU monitoring

### Containers & Virtualisation
- Podman (with Docker compatibility)
- `podman-compose`, `podman-tui`
- Waydroid — Android in a container

### AI / ML
- Ollama (CUDA, listening on `0.0.0.0:11434`)

### Remote Desktop
- Sunshine — game streaming server (NVENC/CUDA, Wayland)

### Web Dev
- `pnpm` — Node.js package manager
- `nix-ld` — run unpatched binaries

---

# Structure

```
nixos-config/
├── modules/          # NixOS system modules
├── dotfiles/         # Dotfiles managed via stow
│   ├── tmux/
│   └── vscode/
├── shells/modules/   # Reusable devShell modules
│   ├── cuda-python.nix   # Python + uv + CUDA base shell
│   ├── qt-dev.nix        # Qt runtime libs + env vars
│   └── latex.nix
├── configuration.nix
└── flake.nix
```

For DeepLearning projects, reusable shells are exported via `lib.mkCudaPythonShell` and `lib.mkQtDevShell` and can be consumed by project flakes:

```nix
{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-config.url = "path:/home/<your user>/nixos-config";
    nixos-config.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = { self, nixpkgs-unstable, nixos-config }: {
    devShells.x86_64-linux.default = let
      unstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      base = nixos-config.lib.mkCudaPythonShell { pkgs = unstable; inherit unstable; };
      qt = nixos-config.lib.mkQtDevShell { inherit unstable; };
    in unstable.mkShell {
      buildInputs = base.buildInputs ++ qt.buildInputs;
      shellHook = base.shellHook + qt.shellHook;
    };
  };
}
```

# Install

1. ```sudo ln -s ~/nixos-config /etc/nixos```
2. ```sudo nixos-rebuild switch --flake```
3. ```nix-shell -p pre-commit --run "pre-commit install"```
4. ```pre-commit install```
5. ```bash run_stow.sh```

# Design Decisions

**Why stow instead of home-manager for dotfiles:**
home-manager can manage dotfiles via `home.file`, which sets symlinks automatically during `nixos-rebuild switch`. However, it marks the target files as read-only. VSCode writes back to `settings.json` during normal usage (e.g. when changing settings via UI), which breaks under home-manager. stow is used instead to keep the files writable while still linking them from this repo.

# Notes

For games in steam (enable borderless window) + this as launch options:
```
SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 PROTON_NO_GRAB=1 %command%
```
