{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.virtualisation.vm9;

  # duplicated code from overlay.nix
  fsOpts = [ "hjfs" "cwfs" ];
  archOpts = [ "amd64" "arm64" "386" ];
in
{
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
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.drawtermPackage
    ];
  };


}

