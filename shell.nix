{
  pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; },
}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    vm9.drawterm
    curl
    nix-prefetch
  ];
  shellHook = ''
    latest() {
      LATEST="$(curl https://build.9front.org/9front/latest)"
    }
    amd64() {
      export SOURCE9="https://build.9front.org/9front/9front-$LATEST.amd64.qcow2.gz"
      export HASH9=$(nix-prefetch-url $SOURCE9)
    }
    newtest() {
      latest
      amd64
      nix run '.#setup-vm-cwfs-amd64-custom' --impure
      echo 'cd /sys/src && mk nuke && mk install' | nix run '.#run-vm-cwfs-amd64-custom' --impure -- -nogui
    }
    reltest() {
      nix run '.#setup-vm-cwfs-amd64'
      echo 'cd / && sysupdate && cd /sys/src && mk nuke && mk install' | nix run '.#run-vm-cwfs-amd64' --impure -- -nogui
    }
  '';
}
