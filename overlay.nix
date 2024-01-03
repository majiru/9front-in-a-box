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
      (a: { name = "vm-${a.fs}-${a.arch}"; value = mkvm { fs = a.fs; arch = a.arch; }; arch = a.arch; })
      (prev.lib.attrsets.cartesianProductOfSets { fs = fsOpts; arch = archOpts; }));

  mksetup = { vm, arch }:
    callPackage (./script.nix) { run = run; create = "yes"; inherit vm arch; };

  allsetup = map (a: { name = "setup-${a.name}"; value = mksetup { vm = a.value; arch = a.arch; }; }) allvm;

  mkrun = { vm, arch }:
    callPackage (./script.nix) { run = run; inherit vm arch; };

  allrun = map (a: { name = "run-${a.name}"; value = mkrun { vm = a.value; arch = a.arch; }; }) allvm;

  mame = { mame = prev.libsForQt5.callPackage (./mame) { }; };

  _9vx = { _9vx = callPackage (./9vx) { }; };

  pkgs = (builtins.listToAttrs (allvm ++ allsetup ++ allrun)) // mame // _9vx;
in
{
  vm9 = pkgs;
}

