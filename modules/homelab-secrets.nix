{ config, pkgs, sops, ... }:
{
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.defaultSopsFile = ../.secret.env;
  sops.defaultSopsFormat = "dotenv";
  sops.secrets.K3S_TOKEN = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
