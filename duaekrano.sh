#!/bin/bash

#killing previous x11vnc process 
killall x11vnc
outputpid=0

#setting up the mobile screen
gtf 1280 800 60 && 
xrandr --newmode "1280x800_60.00"  83.46  1280 1344 1480 1680  800 801 804 828  -HSync +Vsync&& 
xrandr --addmode VIRTUAL1 1280x800_60.00 && 
xrandr --output VIRTUAL1 --mode 1280x800_60.00 --right-of eDP1 &

#reading options from keyboard
read -n1 -r -p "Press option to continue: 
  Press [1] to PTK Laptop without second screen
  Press [2] to PTK laptop with second screen  " key

if [ "$key" = '1' ]; then
  x11vnc -clip 1280x800+1366+0 >/dev/null 2>&1 &
  outputpid=$!
elif [ "$key" = '2' ]; then
  x11vnc -clip 1280x800+1366+1080 >/dev/null 2>&1 &
  outputpid=$!
else
  printf "Error, invalid option"
  exit 1
fi

#getting info about net connections
interface=$(route | grep "default" | awk '{print $8}')
sleep 2 && port=$(ss -l -p -n | grep $outputpid  | awk '/*\:/ {print $5}' | cut -d ':' -f 2)
ip=$(ifconfig $interface | grep "inet addr:" | awk '{print $2}' | cut -d ':' -f 2)

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
./gnirehtet relay >/dev/null 2>&1 & ./gnirehtet install && ./gnirehtet start