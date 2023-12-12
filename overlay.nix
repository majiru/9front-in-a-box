final: prev:
let
  callPackage = prev.lib.callPackageWith prev;
in
{
  vm9 = {
    vm = callPackage (./vm.nix) { };
    vm-amd64 = callPackage (./vm.nix) { arch = "amd64"; };
    vm-arm64 = callPackage (./vm.nix) { arch = "arm64"; };

    vm-cwfs = callPackage (./vm.nix) { fs = "cwfs"; };
    vm-cwfs-amd64 = callPackage (./vm.nix) { fs = "cwfs"; arch = "amd64"; };
    vm-cwfs-arm64 = callPackage (./vm.nix) { fs = "cwfs"; arch = "arm64"; };

    vm-hjfs = callPackage (./vm.nix) { fs = "hjfs"; };
    vm-hjfs-amd64 = callPackage (./vm.nix) { fs = "hjfs"; arch = "amd64"; };
    vm-hjfs-arm64 = callPackage (./vm.nix) { fs = "hjfs"; arch = "arm64"; };
  };
}

