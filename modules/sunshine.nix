{
  config,
  pkgs,
  ...
}: {
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # für Wayland
    openFirewall = false; # nur LAN, siehe extraInputRules unten
  };

  # Sunshine nur aus dem lokalen Subnetz erreichbar, nicht aus dem Internet
  networking.firewall.extraInputRules = ''
    ip saddr 192.168.0.0/24 tcp dport { 47984, 47989, 47990, 48010 } accept
    ip saddr 192.168.0.0/24 udp dport { 47998, 47999, 48000, 48010 } accept
  '';

  hardware.uinput.enable = true;
  users.users.eumel.extraGroups = ["input"];

  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="input", SYMLINK+="uinput"
  '';

  # Optional: CUDA-Support für NVENC Hardware-Encoding
  services.sunshine.package = pkgs.sunshine.override {
    cudaSupport = true;
    cudaPackages = pkgs.cudaPackages;
  };
}
