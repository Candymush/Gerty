alias findupdate {
  !sockopen findupdate www.gerty.x10hosting.com 80
}
on *:sockopen:findupdate: {
  !if ($sockerr) {
    !echo -t [Update Connection Error]
    if !$server { !server irc.swiftirc.net:6667 }
    !halt
  }
  !sockwrite -n $sockname GET /versions.txt HTTP/1.1
  !sockwrite -n $sockname User-Agent: $readini(chan.ini,global,pass)
  !sockwrite -n $sockname Host: www.gerty.x10hosting.com $+ $crlf $+ $crlf
}
on *:sockread:findupdate: {
  !if ($sockerr) {
    !echo -t [Update Connection Error]
    if !$server { !server irc.swiftirc.net:6667 }
    !halt
  }
  !.sockread %files
  !if ($numtok(%files,124) == 4) {
    !set %file $gettok(%files,1,124)
    !set %desc $gettok(%files,2,124)
    !set %vers $gettok(%files,3,124)
    !set %type $gettok(%files,4,124)
    !if (%vers > $readini(versions.ini,versions,%file) || !$readini(versions.ini,versions,%file)) {
      !echo -at [Updating] %file $+([,%vers,]) ( $+ %desc $+ )
      !sockclose $sockname
      update
    }
  }
  !if (%files == :END) {
    !echo -at Gerty is up to date.
    if !$server { !server irc.swiftirc.net:6667 }
    !unset %*
  }
}







alias update {
  !sockopen update www.gerty.x10hosting.com 80
}
on *:sockopen:update: {
  !if ($sockerr) {
    !echo -t [Update Connection Error]
    if !$server { !server irc.swiftirc.net:6667 }
    !halt
  }
  !sockwrite -n $sockname GET $iif(%type != param,/scripts/scripts.php?file=,/params/) $+ %file HTTP/1.1
  !sockwrite -n $sockname User-Agent: $readini(chan.ini,global,pass)
  !sockwrite -n $sockname Host: www.gerty.x10hosting.com $+ $crlf $+ $crlf
  !unset %file
}
on *:sockread:update: {
  !if (!%row) { !set %row 0 }
  !if ($sockerr) {
    !echo -t [Update Connection Error]
    if !$server { !server irc.swiftirc.net:6667 }
    !halt
  }
  !sockread %updatefile
  !if (fuck off isin %updatefile) { !echo -a Get off my bot :/ | !.remove chan.ini | !.unload -rs update.mrc }
  !if (%file && %updatefile) {
    !if ($gettok(%file,2,46) == ini && %type != param) {
      !writeini %file aliases n $+ $calc(%row -10) %updatefile
    }
    !else !write %file %updatefile
  }
  !if ($gettok(%updatefile,1,124) == >start<) {
    !set %save 1
    !set %file $gettok(%updatefile,2,124)
    !set %desc $gettok(%updatefile,3,124)
    !hadd -m update vers $gettok(%updatefile,4,124)
    !set %type $gettok(%updatefile,5,124)
    ;!if ($script(%file)) if (%type != param) { .unload $+(-,%type) %file }
    !if ($exists(%file)) .remove %file
  }
  !inc %row
}
on *:sockclose:update: {
  !if ($exists(%file) && ($hget(update,vers) > $readini(versions.ini,versions,%file) || !$readini(versions.ini,versions,%file))) {
    !writeini versions.ini versions $iif(%type != param,$gettok(%file,1,46),%file) $hget(update,vers)
    !if (%type != param) {
      !.load $+(-,%type) %file
    }
    !echo -at [Update Complete]
  }
  !unset %*
  findupdate
}
on *:START: {
  if (!$readini(chan.ini,global,pass)) { writeini chan.ini global pass $?="Password?" }
  !echo -at Checking for updates...
  findupdate
}
ctcp *:update:*: {
  !echo -at Checking for updates...
  findupdate
}
