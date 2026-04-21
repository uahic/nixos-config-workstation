{
  config,
  pkgs,
  ...
}: {
  fileSystems."/mnt/share" = {
    device = "192.168.0.234:/zpool0/share";
    fsType = "nfs";
    options = ["vers=4" "x-systemd.automount" "noauto"];
  };

  fileSystems."/mnt/980pro" = {
    device = "/dev/disk/by-uuid/143ED0883ED063F0";
    fsType = "ntfs";
    options = ["uid=1000" "gid=100" "umask=022" "rw" "nofail"];
  };
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/98e8581e-0bdc-4817-aa35-915a0af9dd04"; # blkid /dev/sda1
    fsType = "ext4";
    options = ["defaults"];
  };

  systemd.tmpfiles.rules = [
    "d /data/workspaces 0755 eumel users -"
    "d /data/games      0755 eumel users -"
  ];
}
