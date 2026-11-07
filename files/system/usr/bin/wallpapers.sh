#!/bin/zsh

WALLPAPERS="/home/paul/wallpapers"

files=( $(find $WALLPAPERS -type f | shuf -n 2) )

hyprctl hyprpaper wallpaper HDMI-A-1, "$files[1]"
hyprctl hyprpaper wallpaper HDMI-A-2, "$files[2]"
