{ lib
, fetchFromGitHub
, multiStdenv
, xorg
, pkgsi686Linux
}:

let
  repo = fetchFromGitHub {
    owner = "9fans";
    repo = "vx32";
    rev = "6f3ef13b488e563c74b4fdb9c144eebe8aa4bfcf";
    hash = "sha256-XBGXd+feO9H/k9MlKD6EvbVLFCfFSJnHQvl17aXqC+s=";
  };
in
multiStdenv.mkDerivation {
  pname = "_9vx";
  version = "0.12";

  nativeBuildInputs = [ xorg.libX11 pkgsi686Linux.xorg.libX11 ];

  src = "${repo}/src";
  makeFlags = [ "prefix=$(out)" ];
  installPhase = ''
    mkdir -p $out/bin
    install 9vx/9vx $out/bin/9vx
  '';

  meta = with lib; {
    homepage = "https://pdos.csail.mit.edu/~baford/vm/";
    description = "Portable, efficient, safe execution of untrusted x86 code";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ moody _9glenda ];
    platforms = platforms.unix;
    mainProgram = "9vx";
  };
}
