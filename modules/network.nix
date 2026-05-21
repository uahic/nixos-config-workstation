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
  networking.nameservers = ["192.168.0.234" "217.154.245.220"];
  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = ["br-microvms" "vm-openclaw"];
  networking.networkmanager.dns = "none";
  networking.nftables.enable = true; # nftables statt iptables-legacy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = []; # nur explizit oeffnen, 53 fur adguard home, 3000 fur unbound
    allowedUDPPorts = [];
    logRefusedConnections = true;
  };

  # ─── systemd-resolved deaktivieren ───────────────────────────
  services.resolved.enable = false;

  # --- Nur lokalen homeserver als DNS erlauben (und meinen remote) ---
  networking.nftables.tables.dns-redirect = {
    family = "inet";
    content = ''
      chain output-dns {
        type filter hook output priority 0; policy accept;

        # Eigene DNS-Anfragen an AdGuard erlauben
        ip daddr 192.168.0.234 udp dport 53 accept
        ip daddr 192.168.0.234 tcp dport 53 accept
        ip daddr 217.154.245.220 udp dport 53 accept
        ip daddr 217.154.245.220 tcp dport 53 accept

        # Alle anderen DNS-Anfragen nach außen blocken
        udp dport 53 reject
        tcp dport 53 reject
      }
    '';
  };
}
