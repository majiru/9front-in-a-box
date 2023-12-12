{ writeScriptBin
, rc
, run
, vm
, pkgsCross

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
    while(~ $1 -*){
    switch($1){
      case -c
        create='yes'
        shift
      }
    }
    if(~ $create 'yes'){
      ${run}/bin/run -arch ${arch} -create ${vm}/9front.qcow2
      exit
    }
    ${run}/bin/run -uboot ${uboot}/u-boot.bin -arch ${arch} $*
  ''
