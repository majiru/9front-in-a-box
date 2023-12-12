final: prev:
let
  callPackage = prev.lib.callPackageWith prev;
in
{
  vm9 = rec {
    run = callPackage (./run) { };

    vm = callPackage (./vm.nix) { };
    vm-amd64 = callPackage (./vm.nix) { arch = "amd64"; };
    vm-arm64 = callPackage (./vm.nix) { arch = "arm64"; };

    run-vm = callPackage (./script.nix) { run = run; vm = vm; };
    run-vm-amd64 = callPackage (./script.nix) { arch = "amd64"; run = run; vm = vm-amd64; };
    run-vm-arm64 = callPackage (./script.nix) { arch = "arm64"; run = run; vm = vm-arm64; };

    setup-vm = callPackage (./script.nix) { create = "yes"; run = run; vm = vm; };
    setup-vm-amd64 = callPackage (./script.nix) { create = "yes"; arch = "amd64"; run = run; vm = vm-amd64; };
    setup-vm-arm64 = callPackage (./script.nix) { create = "yes"; arch = "arm64"; run = run; vm = vm-arm64; };

    vm-cwfs = callPackage (./vm.nix) { fs = "cwfs"; };
    vm-cwfs-amd64 = callPackage (./vm.nix) { fs = "cwfs"; arch = "amd64"; };
    vm-cwfs-arm64 = callPackage (./vm.nix) { fs = "cwfs"; arch = "arm64"; };

    run-vm-cwfs = callPackage (./script.nix) { run = run; vm = vm-cwfs; };
    run-vm-cwfs-amd64 = callPackage (./script.nix) { arch = "amd64"; run = run; vm = vm-cwfs-amd64; };
    run-vm-cwfs-arm64 = callPackage (./script.nix) { arch = "arm64"; run = run; vm = vm-cwfs-arm64; };

    setup-vm-cwfs = callPackage (./script.nix) { create = "yes"; run = run; vm = vm-cwfs; };
    setup-vm-cwfs-amd64 = callPackage (./script.nix) { create = "yes"; arch = "amd64"; run = run; vm = vm-cwfs-amd64; };
    setup-vm-cwfs-arm64 = callPackage (./script.nix) { create = "yes"; arch = "arm64"; run = run; vm = vm-cwfs-arm64; };

    vm-hjfs = callPackage (./vm.nix) { fs = "hjfs"; };
    vm-hjfs-amd64 = callPackage (./vm.nix) { fs = "hjfs"; arch = "amd64"; };
    vm-hjfs-arm64 = callPackage (./vm.nix) { fs = "hjfs"; arch = "arm64"; };

    run-vm-hjfs = callPackage (./script.nix) { run = run; vm = vm-hjfs; };
    run-vm-hjfs-amd64 = callPackage (./script.nix) { arch = "amd64"; run = run; vm = vm-hjfs-amd64; };
    run-vm-hjfs-arm64 = callPackage (./script.nix) { arch = "arm64"; run = run; vm = vm-hjfs-arm64; };

    setup-vm-hjfs = callPackage (./script.nix) { create = "yes"; run = run; vm = vm-hjfs; };
    setup-vm-hjfs-amd64 = callPackage (./script.nix) { create = "yes"; arch = "amd64"; run = run; vm = vm-hjfs-amd64; };
    setup-vm-hjfs-arm64 = callPackage (./script.nix) { create = "yes"; arch = "arm64"; run = run; vm = vm-hjfs-arm64; };
  };
}

