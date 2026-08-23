#!/bin/sh
# waybar picked whichever interface was actually carrying traffic and showed
# bandwidth/signal; this is the coarser macOS version -- default-route
# interface, SSID if it's Wi-Fi, offline icon if there's no route at all.
iface=$(route get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -z "$iface" ]; then
  sketchybar --set "$NAME" icon="󰖪" label="offline"
  exit 0
fi

ssid=$(ipconfig getsummary "$iface" 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2}')

if [ -n "$ssid" ]; then
  sketchybar --set "$NAME" icon="󰖩" label="$ssid"
else
  sketchybar --set "$NAME" icon="󰈀" label="$iface"
fi
