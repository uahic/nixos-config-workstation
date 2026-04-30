{...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "iomem=relaxed"
  ];
  boot.supportedFilesystems = ["nfs"];
  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc" # selten gebraucht, oft CVE-Quelle
    "firewire-core"
    "thunderbolt" # falls nicht benötigt
  ];
}
