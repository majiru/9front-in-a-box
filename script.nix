{
  writeScriptBin,
  rc,
  run,
  vm,
  pkgsCross,
  qemu,
  drawterm,

  arch,
  fs,

  create ? "no",
}:
let
  uboot = pkgsCross.aarch64-multiplatform.ubootQemuAarch64;
  disk = "9front.${fs}.${arch}.qcow2";
in
writeScriptBin "run.sh" ''
  #!${rc}/bin/rc

  if(~ ${create} 'yes'){
    ${qemu}/bin/qemu-img create -f qcow2 -F qcow2 -o 'backing_file='${vm}/9front.qcow2 ${disk}
    exit
  }
  ${run}/bin/run -qpath ${qemu}/bin -uboot ${uboot}/u-boot.bin -arch ${arch} -disk ${disk} -dt ${drawterm}/bin/drawterm $*
''
