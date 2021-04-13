{ config, pkgs, lib, ... }:

{
  imports = [ <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix> ];

  # Sudo
  security.sudo.wheelNeedsPassword = false;
  # SSH
  services.openssh.enable = true;
  services.openssh.permitRootLogin = lib.mkOverride 10 "no";
  services.openssh.challengeResponseAuthentication = false;
  services.openssh.passwordAuthentication = false;
  # Users
  users.mutableUsers = false;
  users.users.packer = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLzwFBe3z7q3S00wp9hGnLLv5HzyqUaJEJCFPns+D+6INWUD2sg7cVtOtqwhrWEvxuhbcSTa6eJx5MiWkGVfi8XF1zXO9fIwaDXm8dsV4EIAQItilgRUpkJBm0PHp+kTDP2LPFJtVeZvx7X47KGBo3MYxZk0HVVtWlUezG04uI8YV6Iig7kf/iFj/oy6Bc6p0pkLvtzABXHkITYzEKItI1kakiDQBIynJru0+eavryza9KojRNyC1yaThxuDINL/qSjoBCMkVcXtS0Qdz30nlkEbEJdMbSJ8TsdIaOAMhFAC24JNC1M0RV4jZ+rt6DlStLUEiofnyC2kZ7nm06UH9T076LEqfmz1bVMbYCLedRJXUF7f8/rp/ctYVrD/bBU5TEDASbL9bspTeCz3QbXk07bkSdRryrFH1LdK2rXGMh0/6OOHnskon18iWrG+ctycgTAi37I5cH4chuxNcrREisb7OBgmc3I1Ij6LQayaWB+fqHVLu7ve7h1cg/zOKhDec="
    ];
  };
  # Services
  services.postgresql.enable = true;
  services.postgresql.enableTCPIP = true;
  services.postgresql.ensureDatabases = [ "gitea" ];
  services.postgresql.ensureUsers = [
    {
      name = "gitea";
      ensurePermissions = { "DATABASE gitea" = "ALL PRIVILEGES"; };
    }
    {
      name = "superuser";
      ensurePermissions = { "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES"; };
    }
  ];
  services.postgresql.dataDir = "/mnt/data";
  services.postgresql.authentication = ''
    local   all     all                                     trust
    host    replication     all             127.0.0.1/32            trust
    host    replication     all             ::1/128                 trust
    host all all 10.128.0.0/20 trust
  '';
  # FS
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-id/google-database";
    fsType = "xfs";
    autoFormat = true;
    options = [ "noatime" "nodiratime" "discard" ];
  };
  boot.growPartition = true;
}
