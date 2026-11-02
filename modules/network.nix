{...}: let
  local = import ../local.nix;
in {
  networking.interfaces.enp5s0.ipv4.addresses = [
    {
      address = local.hostIp;
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = local.gateway;
  networking.nameservers = [local.nasIp local.externalDns];
  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = ["br-microvms" "vm-openclaw"];
  networking.networkmanager.dns = "none";
  networking.networkmanager.wifi.macAddress = "random";
  networking.networkmanager.wifi.scanRandMacAddress = true;
  networking.networkmanager.ethernet.macAddress = "random";
  networking.nftables.enable = true; # nftables statt iptables-legacy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = []; # nur explizit oeffnen, 53 fur adguard home, 3000 fur unbound
    allowedUDPPorts = [];
    logRefusedConnections = true;
  };

  # ─── systemd-resolved deaktivieren ───────────────────────────
  services.resolved.enable = false;

  #   # --- Nur lokalen homeserver als DNS erlauben (und meinen remote) ---
  #   networking.nftables.tables.dns-redirect = {
  #     family = "inet";
  #     content = ''
  #       chain output-dns {
  #         type filter hook output priority 0; policy accept;

  #         # Eigene DNS-Anfragen an AdGuard erlauben
  #         ip daddr ${local.nasIp} udp dport 53 accept
  #         ip daddr ${local.nasIp} tcp dport 53 accept
  #         ip daddr ${local.externalDns} udp dport 53 accept
  #         ip daddr ${local.externalDns} tcp dport 53 accept

  #         # Alle anderen DNS-Anfragen nach außen blocken
  #         udp dport 53 reject
  #         tcp dport 53 reject
  #       }
  #     '';
  #   };
}
