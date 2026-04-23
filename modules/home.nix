{
  config,
  pkgs,
  ...
}: {
  home-manager.users.eumel = {pkgs, ...}: {
    home.stateVersion = "25.11";

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
          kexAlgorithms = ["mlkem768x25519-sha256" "curve25519-sha256"];
          user = "pluton";
          forwardX11 = true;
        };
      };
    };

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
