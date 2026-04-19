{
  config,
  pkgs,
  ...
}: {
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # für Wayland
    openFirewall = true;
  };

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
