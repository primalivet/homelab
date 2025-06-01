{ config, pkgs, sops, ... }:
{
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets.k3s_token = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
  sops.secrets.tailscale_authkey = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
