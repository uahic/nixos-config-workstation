{
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager.users.eumel = {pkgs, ...}: {
    home.stateVersion = "26.05";
    home.enableNixpkgsReleaseCheck = false;

    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = ["git" "direnv"];
      };
    };

    # Direnv fur automatisches sourcen von flakes
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    # SSH Settings
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "github.com" = {
          kexAlgorithms = ["mlkem768x25519-sha256" "curve25519-sha256"];
        };
        "192.168.0.234" = {
          #kexAlgorithms = ["mlkem768x25519-sha256" "curve25519-sha256"];
          hostname = "192.168.0.234";
          user = "pluton";
          port = 22;
          forwardX11 = true;
        };
      };
    };

    home.activation.copySshConfig = lib.mkAfter ''
      if [ -L "$HOME/.ssh/config" ]; then
        target=$(readlink "$HOME/.ssh/config")
        rm "$HOME/.ssh/config"
        cp "$target" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
      fi
    '';

    dconf.settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminator";
        command = "terminator";
        binding = "<Primary><Super>t";
      };
      "org/gnome/desktop/input-sources" = {
        xkb-options = ["altwin:swap_alt_win"];
      };
      "org/gnome/desktop/wm/preferences" = {
        focus-mode = "sloppy";
      };
    };
  };
}
