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
    echo "x11vnc is running. Stopping process..."
    kill -9 $(get_x11vnc_pid)
  else
    echo "x11vnc stopped"
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
  sed -e "s/\([A-Z0-9]\+\) .*/\1/"
}

get_modeline(){
  w=1280
  h=800
  cvt $w $h | \
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

get_port(){
  ss -l -p -n | \
  grep $outputpid  | \
  awk '/*\:/ {print $5}' | \
  cut -d ':' -f 2
}

process(){
  #TODO: Edit the config file of RealVNC app in Android device to connect this PC
  #adb shell dumpsys activity # to know the activities launched in the android device
  #adb shell am start -n com.package.name/com.package.name.ActivityName

  #Open RealVNC into Android device
  adb shell am start -n \
  com.realvnc.viewer.android/.app.ConnectionChooserActivity >/dev/null 2>&1 &

  #Preparing USB Reverse Tethering
  get_gnirehtet
  # echo "Preparing USB Reverse Tethering..."
  ./gnirehtet relay >/dev/null 2>&1 && \
  ./gnirehtet install &  \
  ./gnirehtet start  &

  #Setting up VNC Server
  kill_x11vnc
  x11vnc -clip 1280x800+1366+0 >/dev/null 2>&1 &
  outputpid=$!

  #getting info about net connections
  interface=$(get_interface)
  sleep 2 && \
  port=$(get_port)
  ip=$(get_ip)

  echo "IP: $ip"
  echo "Port: $port"
  echo "Interface: $interface"

  #Setting up the mobile screen
  monitor=$(get_monitor)
  modeline=$(get_modeline)
  mode_name=`echo $modeline | cut -d'"' -f 2`
  mode_params=${modeline##*'"'}
  xrandr --newmode $mode_name$mode_params &&
  xrandr --addmode VIRTUAL1 $mode_name &&
  xrandr --output VIRTUAL1 --mode $mode_name --right-of $monitor &
}

case "$1" in
  right)
    process "$@";;
  left)
    process "$@";;
  *)
    usage
    exit 0;;
esac
