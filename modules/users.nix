{pkgs, ...}: {
  programs.zsh.enable = true;

  users.mutableUsers = true; # Benutzer/Passwörter rein deklarativ (=> set false)

  users.users.eumel = {
    isNormalUser = true;
    description = "eumel";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5; # kill bei <5% freiem RAM (default 10)
    freeSwapThreshold = 10; # kill bei <10% freiem Swap (default 10)
    extraArgs = [
      "--avoid"
      "'^(Xorg|sshd|systemd.*)$'" # wichtige Prozesse verschonen
      "--prefer"
      "'^(python|python3|jupyter)$'" # bevorzugt ML-Prozesse killen
    ];
  };
}
