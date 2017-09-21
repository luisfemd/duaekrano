#!/bin/bash

set -e # fail on error

usage() {
  cat <<- EOF
Syntax: $0 (left|right) ...

    $0 left
      Set the virtual screen at left to principal monitor.

    $0 right
      Set the virtual screen at right to principal monitor.
EOF
}

kill_x11vnc(){
  if pgrep -x "x11vnc" > /dev/null
  then
      echo "X11VNC is running. Stopping process..."
      kill -9 $(get_x11vnc_pid)
  else
      echo "Stopped"
  fi
}

get_tablet_resolution(){
  echo "hello"
}

get_x11vnc_pid(){
  ps aux | \
  grep x11vnc | \
  grep -v "grep" | \
  awk '{print $2}'
}

get_gnirehtet(){
  if test -e gnirehtet
  then
      echo "Gnirehtet is already downloaded"
  else
      echo "Downloading Gnirehtet"
      wget https://github.com/Genymobile/gnirehtet/releases/download/v1.1.1/gnirehtet-v1.1.1.zip > /dev/null
      unzip gnirehtet-v1.1.1.zip
  fi
}

get_monitor(){
  xrandr | \
  grep " connected" | \
  sed -e "s/\([A-Z0-9]\+\) connected primary.*/\1/"
}

get_modeline(){
  gtf $w $h $frecuency | \
  grep "Modeline" | \
  sed 's: *Modeline ::'
}

get_interface(){
  route | \
  grep "default" | \
  awk '{print $8}'
}

get_ip(){
  ifconfig $interface | \
  grep "inet addr:" | \
  awk '{print $2}' | \
  cut -d ':' -f 2
}

process(){
  kill_x11vnc
  get_gnirehtet

  # exit 1;
  outputpid=0
  frecuency=60
  w=1280
  h=800

  monitor=$(get_monitor)
  modeline=$(get_modeline)
  # echo $monitor
  # exit 1
  echo $modeline
  echo $monitor
  #setting up the mobile screen
  # gtf 1280 800 $frecuency &&
  xrandr --newmode $modeline&&
  xrandr --addmode VIRTUAL1 $[w]x$[h]_60.00 &&
  xrandr --output VIRTUAL1 --mode $[w]x$[h]_60.00 --right-of $monitor &

  #reading options from keyboard
  # read -n1 -r -p "Press option to continue:
  #   Press [1] to option 1
  #   Press [2] to option 2  " key

  # if [ "$key" = '1' ]; then
  x11vnc -clip 1280x800+1366+0 >/dev/null 2>&1 &
  outputpid=$!
  # elif [ "$key" = '2' ]; then
  #x11vnc -clip 1280x800+1366+1080 >/dev/null 2>&1 &
  #outputpid=$!
  # else
  #   printf "Error, invalid option"
  #   exit 1
  # fi

  #getting info about net connections
  interface=$(get_interface)
  sleep 2 && port=$(ss -l -p -n | grep $outputpid  | awk '/*\:/ {print $5}' | cut -d ':' -f 2)
  ip=$(get_ip)

  echo "IP: $ip"
  echo "Port: $port"
  echo "Interface: $interface"

  #TODO: Edit the config file of RealVNC app in Android device to connect this PC
  #adb shell dumpsys activity # to know the activities launched in the android device
  #adb shell am start -n com.package.name/com.package.name.ActivityName

  #Open RealVNC into Android device
  adb shell am start -n com.realvnc.viewer.android/.app.ConnectionChooserActivity

  #Preaparing USB Reverse Tethering
  echo "Preparing USB Reverse Tethering..."
  ./gnirehtet relay >/dev/null 2>&1 & \
  ./gnirehtet install && \
  ./gnirehtet start
}

case "$1" in
  right)
      process "$@";;
  left)
      process "$@";;
*)
  usage
  exit 0
  ;;
esac
