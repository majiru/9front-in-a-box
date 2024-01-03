{ fetchurl
, arch ? "amd64"
, release ? "10277"
, sourceType ? {
    amd64 = "qcow2";
    arm64 = "qcow2";
    "386" = "iso";
  }.${arch}
, sourceUrl ? "https://iso.only9fans.com/release"
, source ? fetchurl {
    url = "${sourceUrl}/9front-${release}.${arch}.${sourceType}.gz";
    hash = {
      amd64-qcow2 = "sha256-9NaYKc58zKQJC8gPL6a3cRSP+U+OFhCgUCqG2FSGGjE=";
      amd64-iso = "sha256-+/Gj8Bc2nuJkeSIf7sQ6ZgypSyA37SJVUpUapi9KBE8=";
      arm64-qcow2 = "sha256-GUkJG2dJl9QK7Gl09PFjTE/vweZ4euKQtgS2sTtDH+Y=";
      "386-iso" = "sha256-oEoOxxea/8PBKJ8050jk+2AbkSTeS1A2AxgR8cQyH1U=";
    }."${arch}-${sourceType}";
  }
}:
source
