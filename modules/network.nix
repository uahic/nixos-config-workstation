{
  config,
  pkgs,
  ...
}: {
  networking.interfaces.enp5s0.ipv4.addresses = [
    {
      address = "192.168.0.5";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = ["1.1.1.1"];
  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = ["br-microvms" "vm-openclaw"];
  networking.nftables.enable = true; # nftables statt iptables-legacy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = []; # nur explizit oeffnen
    allowedUDPPorts = [];
    logRefusedConnections = true;
  };
}
