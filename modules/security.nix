{...}: {
  services.openssh.enable = false;

  security.sudo.execWheelOnly = true;
  security.sudo.extraConfig = ''
    Defaults lecture = always
    Defaults passwd_timeout = 1
  '';

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0";
    }
  ];
}
