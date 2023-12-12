{ lib
, buildGoModule
}:
buildGoModule {
  pname = "run";
  version = "0.1";

  src = ./.;

  vendorHash = "sha256-f1qukX/vDd+dehv9y9pv0NqNt6D/LWZ3ufeJOsqvG2Y=";

  meta = with lib; {
    description = "Manages the 9front-in-a-box vm";
    homepage = "https://github/majiru/9front-in-a-box/run";
    license = licenses.mit;
    maintainers = with maintainers; [ moody ];
  };
}
