{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.microvm.nixosModules.host
    ./openclaw-vm.nix
  ];

  # ─── Bridge + tap manuell anlegen (kein networkd nötig) ──────
  systemd.services.openclaw-net-setup = {
    description = "Bridge + tap für OpenClaw microvm";
    wantedBy = ["multi-user.target"];
    before = ["microvm@openclaw.service"];
    after = ["network-pre.target"];
    path = [pkgs.iproute2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Bridge
      if ! ip link show br-microvms >/dev/null 2>&1; then
        ip link add name br-microvms type bridge
      fi
      ip link set br-microvms up
      ip addr replace 10.0.100.1/24 dev br-microvms

      # Tap-Interface für die VM (User microvm muss existieren)
      if ! ip link show vm-openclaw >/dev/null 2>&1; then
        ip tuntap add vm-openclaw mode tap user microvm
      fi
      ip link set vm-openclaw up
      ip link set vm-openclaw master br-microvms

      # IP-Forwarding für NAT
      echo 1 > /proc/sys/net/ipv4/ip_forward
    '';
    preStop = ''
      ip link del vm-openclaw 2>/dev/null || true
      ip link del br-microvms 2>/dev/null || true
    '';
  };

  # ─── nftables-Regeln: NAT + selektive Freigabe ──────────────
  networking.nftables.tables.openclaw-nat = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority 100;
        ip saddr 10.0.100.0/24 oifname != "br-microvms" masquerade
      }
    '';
  };

  # Nur Verkehr von der Bridge darf zu Ollama (11434)
  networking.firewall.extraInputRules = ''
    iifname "br-microvms" tcp dport 11434 accept
  '';

  # ─── Secrets stagen ─────────────────────────────────────────
  systemd.services.openclaw-prepare-secrets = {
    description = "Stage OpenClaw secrets for microvm";
    wantedBy = ["microvm@openclaw.service"];
    before = ["microvm@openclaw.service"];
    after = ["openclaw-net-setup.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      dir=/var/lib/microvms/openclaw/secrets
      mkdir -p "$dir"

      if [ ! -f "$dir/gateway-token" ]; then
        ${pkgs.coreutils}/bin/cat /proc/sys/kernel/random/uuid \
          | ${pkgs.coreutils}/bin/tr -d '-' > "$dir/gateway-token"
        chmod 0444 "$dir/gateway-token"
      fi

      if [ ! -f "$dir/searxng-secret" ]; then
        ${pkgs.openssl}/bin/openssl rand -hex 32 > "$dir/searxng-secret"
        chmod 0444 "$dir/searxng-secret"
      fi
    '';
  };

  # microvm.nix legt den User automatisch an, aber zur Sicherheit:
  users.users.microvm = {
    isSystemUser = true;
    group = "microvm";
  };
  users.groups.microvm = {};
}
