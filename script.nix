{ writeScriptBin
, rc
, run
, vm
, pkgsCross
, qemu
, drawterm

, arch ? "amd64"
, create ? "no"
}:
let
  uboot = pkgsCross.aarch64-multiplatform.ubootQemuAarch64;
in
writeScriptBin "run.sh"
  ''
    #!${rc}/bin/rc

    create=${create}
    if(~ $create 'yes'){
      ${run}/bin/run -arch ${arch} -create ${vm}/9front.qcow2
      exit
    }
    ${run}/bin/run -qpath ${qemu}/bin -uboot ${uboot}/u-boot.bin -arch ${arch} -dt ${drawterm}/bin/drawterm $*
  ''
