{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.vm9;

  # duplicated code from overlay.nix
  fsOpts = ["hjfs" "cwfs"];
  archOpts = ["amd64" "arm64" "386"];
in {
  options.virtualisation.vm9 = {
    enable = lib.mkEnableOption "enable the vm9 service.";

    drawtermPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.drawterm;
      defaultText = lib.literalExpression "pkgs.drawterm";
      example = lib.literalExpression "pkgs.drawterm-wayland";
      description = lib.mdDoc "`drawterm` package to use.";
    };

    vm = lib.mkOption {
      description = "9front VMs";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          disk = {
            size = lib.mkOption {
              type = lib.types.str;
              default = 50;
              example = 30;
              description = "disk size in GB.";
            };
            fs = lib.mkOption {
              type = lib.types.enum fsOpts;
              default = "hjfs";
              example = "cwfs";
              description = "9front file system to use.";
            };
          };
          arch = lib.mkOption {
            type = lib.types.enum archOpts;
            default = "amd64";
            example = "arm64";
            description = "arch of the VM";
          };
        };
      });
    };

    networking = {
      enable = lib.mkEnableOption "automatically set up virtual networks.";

      bridgeName = lib.mkOption {
        type = lib.types.str;
        default = "br0";
        description = "Name of the bridged interface for use by libvirt guests";
      };

      externalInterface = lib.mkOption {
        type = lib.types.str;
        default = "vnet0";
        description = "Name of the external interface for NAT masquerade";
      };
    };
  };
  config =
    lib.mkIf cfg.enable {
      environment.systemPackages = [
        cfg.drawtermPackage
      ];
    }
    // lib.mkIf cfg.networking.enable {
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      # TODO handle tap in module no qemu
      # systemd.network.netdevs = let
      #   mkTap = {name}: {
      #     ${name} = {
      #       matchConfig = {
      #         Name = "${name}";
      #       };
      #       tapConfig = {
      #         Group = "users"; # TODO
      #       };
      #       netdevConfig = {
      #         Description = "This is a tap device for a 9front VM";
      #         Name = "${name}";
      #         Kind = "tap";
      #       };
      #       networkConfig = {
      #         Description = "This is a tap device for a 9front VM";
      #         LinkLocalAddressing = "no";
      #         LLMNR = "no";
      #         IPv6AcceptRA = "no";
      #         Bridge = "${cfg.networking.bridgeName}";
      #       };
      #       extraConfig = ''
      #         [Network]
      #       '';
      #     };
      #   };
      # in
      #   {
      #   }
      #   // mkTap {name = "tap3";};
      networking = {
        bridges."${cfg.networking.bridgeName}".interfaces = [];
        interfaces."${cfg.networking.bridgeName}" = {
          ipv4.addresses = [
            {
              address = "10.0.2.1";
              prefixLength = 24;
            }
            {
              address = "10.0.2.2";
              prefixLength = 24;
            }
          ];
        };
        nat = {
          enable = true;
          internalInterfaces = [cfg.networking.bridgeName];
          inherit (cfg.networking) externalInterface;
        };
      };

      services.kea.dhcp4 = {
        enable = true;
        settings = let
          router = "10.0.2.2";
          subnet = "10.0.2.0";
          rangeStart = "10.0.2.14";
          rangeEnd = "10.0.2.100";
        in {
          interfaces-config = {
            interfaces = [
              "${cfg.networking.bridgeName}/${router}"
            ];
          };
          lease-database = {
            name = "/var/lib/kea/dhcp4.leases";
            persist = true;
            type = "memfile";
          };
          rebind-timer = 2000;
          renew-timer = 1000;
          subnet4 = [
            {
              pools = [
                {
                  pool = "${rangeStart} - ${rangeEnd}";
                  option-data = [
                    {
                      "name" = "domain-name-servers";
                      "code" = 6;
                      "space" = "dhcp4";
                      "csv-format" = true;
                      "data" = "1.1.1.1";
                    }
                  ];
                }
              ];
              subnet = "${subnet}/24";
            }
          ];
          valid-lifetime = 4000;
        };
      };
      environment.etc."qemu/bridge.conf".text = ''
        allow ${cfg.networking.bridgeName}
      '';
    };
}

