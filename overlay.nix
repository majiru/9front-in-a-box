final: prev:
let
  callPackage = final.callPackage;

  fsOpts = [
    "hjfs"
    "cwfs"
    "gefs"
  ];
  archOpts = [
    "amd64"
    "arm64"
    "386"
  ];

  run = callPackage ./run { };

  mkvm =
    {
      fs ? "hjfs",
      arch ? "amd64",
      name ? "vm-${fs}-${arch}",
    }:
    {
      value = callPackage ./vm.nix { inherit fs arch; };
      inherit fs arch name;
    };

  allrelvm = [
    (mkvm { name = "vm"; })
  ]
  ++ (map (
    a:
    (mkvm {
      name = "vm-${a}";
      fs = a;
    })
  ) fsOpts)
  ++ (map (
    a:
    (mkvm {
      name = "vm-${a}";
      arch = a;
    })
  ) archOpts)
  ++ (map
    (
      a:
      (mkvm {
        inherit (a) fs;
        inherit (a) arch;
      })
    )
    (
      prev.lib.attrsets.cartesianProduct {
        fs = fsOpts;
        arch = archOpts;
      }
    )
  );

  extra = {
    drawterm = callPackage ./drawterm.nix { };
  };

  allvm =
    allrelvm
    ++ map (a: {
      name = "${a.name}-custom";
      inherit (a) fs arch;
      value = callPackage ./vm.nix {
        inherit (a) fs arch;
        source = final.fetchurl {
          url = builtins.getEnv "SOURCE9";
          sha256 = builtins.getEnv "HASH9";
        };
      };
    }) allrelvm;

  vm2script =
    {
      vm,
      create ? "no",
    }:
    callPackage ./script.nix {
      vm = vm.value;
      inherit (extra) drawterm;
      inherit (vm) arch fs;
      inherit run create;
    };

  allsetup = map (a: {
    name = "setup-${a.name}";
    value = vm2script {
      vm = a;
      create = "yes";
    };
  }) allvm;

  allrun = map (a: {
    name = "run-${a.name}";
    value = vm2script { vm = a; };
  }) allvm;

  pkgs = (builtins.listToAttrs (allvm ++ allsetup ++ allrun)) // extra;
in
{
  vm9 = pkgs;
}
