{ config, lib, pkgs, name, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.package = pkgs.nixVersions.latest;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  networking.hostName = name; # Define your hostname.

  networking.firewall = {
   enable = true;
   allowedTCPPorts = [
     6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
     # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
     # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
   ];
   allowedUDPPorts = [
     # 8472 # k3s, flannel: required if using multi-node for inter-node networking
   ];
  };

  networking.interfaces.enp0s1.ipv4.addresses = [
   {
     address = "192.168.1.10";
     prefixLength = 24;
   }
  ];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" ];


  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
  };

  services.k3s = {
    enable = true;
    role = "server";
  };

  users.users.gustaf = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$.TJ/b9UC4jo3TOvz$DqfuGS5oj6O.X/zyHRRP9pjHJ9MbqcOHvfjSZbOFoBgMOE6dBvwXCbdqG0qkX2tC27pFZ0Hzgbics5TH2XDmU/";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDp7yzlnHtcS7TliFQcaHKiojr6frzHsZ62F5kp62eeE0mmACB4vnwvWF+z6jusZpqZ1vNej5Sjh6O1phj4igtTQ5OV+D9imbhBmFvGfP9hvaIvWgdqBipeJ454u9G8n7rx9rgiPekzJfNuCpjRqJrDdc8upQJfTZTVzuDjA3yPg4rVq9L4wJWBZUzukzDEKRjrkmXE6Cuwa5xUhpViedz49+IIQypSXT/v3REnrsCO0qNm45kXhEMFH9qv12HS56jZW6ndx+OJjfhXyab8UChivFiAt/QpF3bdhtRCJ74M0bAFSsAb3UhGJ/37mslatZUH0NQpQdzIrWpzIYUFMAmKPN0pyOEzo7IVMlSdD9Tm8DkpeXPv8qDF/CBo6ms7FpDqPKm+J2kH9V7lo88Jm0FjFLYBGXcTv4a92o+nkYAB0Ga/thhbqL/Q2Zmjf+0X8S2QL5v7hey9HmVNV60hAn0merFesg2BX7oVp7QxyvUy8Vj1GnB41Ph2BSFvLhShpW8= gustaf@Gustafs-MacBook-Pro.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJm0n5LCXPRWjIRLxILZmmeWzDXjjuVD8UFoWLrXNu9 gustaf.holm@icloud.com"
    ];
    packages = with pkgs; [ ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}

