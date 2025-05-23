{ config, pkgs, nix-sops, ... }:
{
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.k3s_token = {
    owner = "root";
    group = "root";
    mode = "0400";
  }
}
