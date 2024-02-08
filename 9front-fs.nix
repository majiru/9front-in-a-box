{ lib
, stdenv
, fetchurl
, p7zip

, arch ? "amd64"
, release ? "10277"
, sourceType ? {
    amd64 = "iso";
    arm64 = "qcow2"; # TODO support unpacking qcow2
    "386" = "iso";
  }.${arch}
, sourceUrl ? "https://iso.only9fans.com/release"
, source ? (import ./9front-src.nix { inherit fetchurl arch release sourceType sourceUrl; })
}:
stdenv.mkDerivation rec {
  pname = "_9front-${arch}";
  version = "${release}";

  src = source;

  # we don't want nix to do stuff like patchelf
  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    gunzip -c ${src} > 9front.iso
  '';
  installPhase = ''
    mkdir -p "$out"
    # 9front uses weird chars in some doc paths but I can't figure out how to exclude them so we just ignore the errors.
    yes '
    a' | ${p7zip}/bin/7z x -y 9front.iso  -o"$out" || true

    '';

  meta = with lib; {
    description = "upacked 9front iso";
    homepage = "https://github/majiru/9front-in-a-box/";
    license = licenses.mit;
    maintainers = with maintainers; [ moody ];
  };
}
