{
  writeScriptBin,
  drawterm,
  drawterm-wayland,
  rc-9front,
}:
writeScriptBin "drawterm" ''
  #!${rc-9front}/bin/rc

  switch($XDG_SESSION_TYPE){
  case 'wayland'
    exec ${drawterm-wayland}/bin/drawterm $*
  case 'x11'
    exec ${drawterm}/bin/drawterm $*
  case *
    exec ${drawterm}/bin/drawterm $*
  }
''
