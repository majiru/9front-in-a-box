{ lib
, stdenv
, fetchurl
, qemu
, expect
, writeScript
, pkgsCross

, fs ? "hjfs"
, size ? "50G"
, arch ? "amd64"
, source ? fetchurl {
    url = "https://iso.only9fans.com/release/9front-10277.${arch}.qcow2.gz";
    hash = {
      amd64 = "sha256-9NaYKc58zKQJC8gPL6a3cRSP+U+OFhCgUCqG2FSGGjE=";
      arm64 = "sha256-GUkJG2dJl9QK7Gl09PFjTE/vweZ4euKQtgS2sTtDH+Y=";
    }."${arch}";
  }
}:
let
  uboot = pkgsCross.aarch64-multiplatform.ubootQemuAarch64;
  qbin = {
    amd64 = "qemu-system-x86_64 -enable-kvm -m 2G -smp 4 -drive file=./9front.qcow2,media=disk,if=virtio,index=0 -drive file=$env(TARGET),index=1,media=disk,if=virtio -nographic -nic none";
    arm64 = "qemu-system-aarch64 -M virt-2.12,gic-version=3 -cpu cortex-a72 -m 4G -smp 4 -bios ${uboot}/u-boot.bin  -drive file=./9front.qcow2,if=none,id=disk1 -drive file=$env(TARGET),index=1,media=disk,if=none,id=disk2 -device virtio-blk-pci-non-transitional,drive=disk1  -device virtio-blk-pci-non-transitional,drive=disk2 -nographic";
  }."${arch}";
  preboot = {
    amd64 = ''
      expect "bootfile="
      send "\n"
      expect ">"
      send "console=0\n"
      expect ">"
      send "boot\n"
    '';
    arm64 = "";
  }."${arch}";
  expectScript = writeScript "expect.sh"
    ''
      #!${expect}/bin/expect -f
      set timeout -1
      set debug 5
      spawn ${qbin}
      ${preboot}
      expect "bootargs is"
      send "\n"
      expect "user"
      send "\n"
      expect "%"

      send "inst/start\n"
      expect "Task to do"

      send "configfs\n"
      expect "File system"
      send "\n"
      expect "Task to do"

      send "partdisk\n"
      expect "Disk to partition"
      send "sdG0\n"
      expect "Install mbr"
      send "mbr\n"
      expect ">>>"
      send "w\n"
      expect ">>>"
      send "q\n"
      expect "Task to do"

      send "prepdisk\n"
      expect "Plan 9 partition"
      send "/dev/sdG0/plan9\n"
      expect ">>>"
      send "w\n"
      expect ">>>"
      send "q\n"
      expect "Task to do"

      send "mountfs\n"
      expect "Cwfs cache partition"
      send "/dev/sdG0/fscache\n"
      expect "Cwfs worm partition"
      send "/dev/sdG0/fsworm\n"
      expect "Cwfs other partition"
      send "/dev/sdG0/other\n"
      expect "Ream the filesystem"
      send "yes\n"
      expect "Task to do"

      send "configdist\n"
      expect "Distribution is from"
      send "local\n"
      expect "Task to do"

      send "confignet\n"
      expect "Task to do"

      send "mountdist\n"
      expect "Distribution disk"
      send "/\n"
      expect "Location of archives"
      send "/\n"
      expect "Task to do"

      send "copydist\n"
      expect "Task to do"

      send "ndbsetup\n"
      expect "sysname"
      send "\n"
      expect "Task to do"

      send "tzsetup\n"
      expect "Time Zone"
      expect "W-SU"
      send "US_Central\n"
      expect "Task to do"

      send "bootsetup\n"
      expect "Plan 9 FAT partition"
      send "/dev/sdG0/9fat\n"
      expect "Install the Plan 9 master"
      send "yes\n"
      expect "Mark the Plan 9"
      send "yes\n"
      expect "Task to do"

      send "finish\n"
      expect "done halting"
    '';
in
stdenv.mkDerivation rec {
  pname = "vm-${fs}-${arch}";
  version = "0.1";

  nativeBuildInputs = [
    qemu
    expect
  ];

  src = source;

  unpackPhase = ''
    gunzip -c ${src} > 9front.qcow2
  '';

  buildPhase = {
    cwfs = ''
      mkdir -p $out
      qemu-img create -f qcow2 $out/9front.qcow2 ${size}
      TARGET="$out/9front.qcow2" ${expectScript}
    '';
    hjfs = ''
      mkdir -p $out
      mv 9front.qcow2 $out/
    '';
  }."${fs}";
}

