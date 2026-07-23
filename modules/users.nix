{pkgs, ...}: {
  programs.zsh.enable = true;

  users.mutableUsers = true; # Benutzer/Passwörter rein deklarativ (=> set false)

  users.users.eumel = {
    isNormalUser = true;
    description = "eumel";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
    initialPassword = "test";
  };

  users.users.claw = {
    isSystemUser = false;
    isNormalUser = true;
    description = "OpenClaw sandbox user";
    createHome = false;
    shell = pkgs.bash;
    extraGroups = []; # bewusst leer: kein wheel, video, render, docker
    autoSubUidGidRange = true; # subuid/subgid für rootless Podman
  };

  users.users.eumel = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
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
