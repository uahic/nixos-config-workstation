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
}
