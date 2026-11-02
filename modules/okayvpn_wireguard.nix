{...}: {
  boot.kernelModules = ["wireguard"];

  networking.wg-quick.interfaces.okayvpn = {
    configFile = "/etc/wireguard/okayvpn.conf";
    autostart = false;
  };
}
# Zum Checken
# https://10ips.com/residential-ip-checker
# VPN der funzt: OkayVPN
#
# Setup (einmalig als root):
#   sudo mkdir -p /etc/wireguard
#   sudo cp ~/Downloads/wgconf/ok3730383295.conf /etc/wireguard/okayvpn.conf
#   sudo chmod 600 /etc/wireguard/okayvpn.conf
#
# Starten/Stoppen:
#   sudo wg-quick up okayvpn
#   sudo wg-quick down okayvpn

