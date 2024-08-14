#!/bin/bash

# Path to the file that stores the current wallpaper
current_wallpaper_file="/tmp/current_wallpaper_path.txt"
tmp_wallpaper_file="/tmp/current_wallpaper_temp.jpg"
pid_file="/tmp/wallpaper_updater.pid"

# Function to get the current wallpaper path
get_wallpaper_path() {
  swww query | awk -F'currently displaying: image: ' '{print $2}' | head -n 1
}

# Initialize the current wallpaper file
get_wallpaper_path >"$current_wallpaper_file"

# Function to get feh window ID
get_feh_window_id() {
  xprop -root _NET_CLIENT_LIST_STACKING | awk '{print $NF}'
}

# Function to refresh feh by updating the image
refresh_feh() {
  local window_id
  window_id=$(get_feh_window_id)
  if [ -n "$window_id" ]; then
    xdotool windowactivate "$window_id"
    xdotool key --window "$window_id" r # 'r' is the default keybinding for reload in feh
  else
    echo "feh window not found"
  fi
}

# Function to update the wallpaper in feh
update_feh() {
  local new_wallpaper_path
  new_wallpaper_path=$(get_wallpaper_path)

  # Update the temp wallpaper file
  cp "$new_wallpaper_path" "$tmp_wallpaper_file"

  # Start feh with the new wallpaper or refresh it
  if pgrep -x "feh" >/dev/null; then
    refresh_feh
  else
    feh --scale-down --zoom fill "$tmp_wallpaper_file" &
  fi
}

# Check for existing PID file and whether the script is already running
if [ -e "$pid_file" ]; then
  if kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    echo "Script is already running."
    exit 1
  else
    rm "$pid_file"
  fi
fi

# Create PID file
echo $$ >"$pid_file"

# Ensure PID file is removed on exit
trap 'rm -f "$pid_file"' EXIT

# Initial feh setup
update_feh

# Loop to check for wallpaper changes
while true; do
  new_wallpaper_path=$(get_wallpaper_path)

  if [ "$(cat "$current_wallpaper_file")" != "$new_wallpaper_path" ]; then
    echo "$new_wallpaper_path" >"$current_wallpaper_file"
    update_feh
  fi

  # Sleep for a short duration before checking again
  sleep 1
done
