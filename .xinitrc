#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

setxkbmap -model apple_laptop \
  -layout us,ru -variant , \
  -option ctrl:nocaps \
  -option grp:rwin_toggle \
  -option compose:ralt \
  -option grp_led:caps

while true
do
  LOCALTIME=$(date +'%a %F | %H:%M')
  BAT=$(acpi --battery | grep -o '[0-9]\+%')

  xsetroot -name "$LOCALTIME | $BAT"
  sleep 20s
done &

xset s off -dpms
xset r rate 200 50

xcompmgr -c -l0 -t0 -r0 -o.00 &

numlockx &
qutebrowser&
st -e tmux&

exec i3 >/tmp/log.i3 2>&1
