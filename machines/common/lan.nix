{ config, lib, pkgs, ... }: 

with lib;
{
  options.lan = {
    enable = mkEnableOption {
      default = true;
      description = "Enable local network configuration.";
    };

    interface = mkOption {
      type = types.str;
      description = "Network interface to configure.";
      example = "en0sp1";
    };

    ipv4Address = mkOption {
      type = types.str;
      description = "IPv4 address to assign to the interface.";
      example = "192.168.1.10";
    };
  }

  config = mkIf config.lan.enable {
    assertions = [
        {
          assertion = config.lan.interface != "";
          message = "Network interface must be specified with lan.interface.";
        }
        { 
          assertion = config.lan.ipv4Address != "";
          message = "IPv4 address must be specified with lan.ipv4Address.";
        }
    ];
    networking.interfaces."${config.lan.interface}".ipv4.addresses = [
      {
        address = config.myNetworking.ipAddress;
        prefixLength = 24;
      }
    ];
  };
}
