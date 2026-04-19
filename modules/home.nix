{
  config,
  pkgs,
  ...
}: {
  home-manager.users.eumel = {pkgs, ...}: {
    home.stateVersion = "25.11";

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
    };
  };
}
