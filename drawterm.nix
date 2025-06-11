{
  writeScriptBin,
  drawterm,
  drawterm-wayland,
}:
writeScriptBin "drawterm" ''
  #!/usr/bin/env sh

  case $XDG_SESSION_TYPE in
    wayland)
        exec ${drawterm-wayland}/bin/drawterm $*
        ;;
    x11)
        exec ${drawterm}/bin/drawterm $*
        ;;
    *)
        exec ${drawterm}/bin/drawterm $*
        ;;
  esac
''
