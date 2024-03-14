final: prev:
let
  callPackage = prev.lib.callPackageWith prev;

  fsOpts = [ "hjfs" "cwfs" ];
  archOpts = [ "amd64" "arm64" "386" ];

  run = callPackage (./run) { };

  mkvm = { fs ? "hjfs", arch ? "amd64" }:
    callPackage (./vm.nix) { inherit fs arch; };

  allvm =
    [{ name = "vm"; value = mkvm { }; arch = "amd64"; }]
    ++
    (map
      (a: { name = "vm-${a}"; value = mkvm { fs = a; }; arch = "amd64"; })
      fsOpts)
    ++
    (map
      (a: { name = "vm-${a}"; value = mkvm { arch = a; }; arch = a; })
      archOpts)
    ++
    (map
      (a: { name = "vm-${a.fs}-${a.arch}"; value = mkvm { inherit (a) fs; inherit (a) arch; }; inherit (a) arch; })
      (prev.lib.attrsets.cartesianProductOfSets { fs = fsOpts; arch = archOpts; }));

  mksetup = { vm, arch }:
    callPackage (./script.nix) { create = "yes"; inherit run vm arch; };

  allsetup = map (a: { name = "setup-${a.name}"; value = mksetup { vm = a.value; inherit (a) arch; }; }) allvm;

  mkrun = { vm, arch }:
    callPackage (./script.nix) { inherit run; inherit vm arch; };

  allrun = map (a: { name = "run-${a.name}"; value = mkrun { vm = a.value; inherit (a) arch; }; }) allvm;

  mame = { mame = prev.libsForQt5.callPackage (./mame) { }; };

  _9vx = { _9vx = callPackage (./9vx) { }; };

  nine = { nine = callPackage (./nine) { }; };

  pkgs = (builtins.listToAttrs (allvm ++ allsetup ++ allrun)) // mame // _9vx // nine;
in
{
  vm9 = pkgs;
}

