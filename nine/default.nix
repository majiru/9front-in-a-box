{ lib
, fetchFromGitHub
, stdenv
}:

stdenv.mkDerivation {
  pname = "nine";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "michaelforney";
    repo = "nine";
    rev = "c168349497922ab3f5afc7195089f20a529520cd";
    hash = "sha256-rFtszVzUllTNNSYFMyanwytQdZnB7yWENbzjvJ3EVcQ=";
  };
  installPhase = ''
    mkdir -p $out/bin
    install nine $out/bin/nine
  '';

  meta = with lib; {
    homepage = "https://github.com/michaelforney/nine";
    description = "wine for 9";
    license = with licenses; [ unlicense ];
    maintainers = with maintainers; [ moody _9glenda ];
    platforms = platforms.unix;
    mainProgram = "nine";
  };
}
