{
  config,
  pkgs,
  ...
}: {
  home-manager.users.eumel = {pkgs, ...}: {
    home.stateVersion = "25.11";
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          kexAlgorithms = ["mlkem768x25519-sha256" "curve25519-sha256"];
        };
      };
      matchBlocks = {
        "192.168.0.234" = {
          kexAlgorithms = ["mlkem768x25519-sha256" "curve25519-sha256"];
          User = "pluton";
          ForwardX11 = "yes";
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
