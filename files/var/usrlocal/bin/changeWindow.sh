#!/bin/zsh

typeset -A menu_to_workspace
typeset -A title_count
typeset -A menu_to_icon

# Function to get icon from desktop entry
get_icon() {
  local class="$1"
  local icon_name desktop_file

  desktop_file=$(grep -rilE "StartupWMClass=.*$class|Exec=.*$class" /usr/share/applications/*.desktop 2>/dev/null | head -n1)
  if [[ -n "$desktop_file" ]]; then
    icon_name=$(grep -m1 '^Icon=' "$desktop_file" | cut -d= -f2)
    [[ -z "$icon_name" ]] && icon_name="application-x-executable"
  else
    icon_name="application-x-executable"
  fi
  echo "$icon_name"
}

# Read each window from hyprctl JSON
while IFS=$'\t' read -r title ws class; do
  [[ -z "$title" || -z "$ws" ]] && continue

  # Skip special workspaces (Hyprland marks them as "special":true)
  [[ "$ws" == special:* ]] && continue

  # Handle duplicates
  ((title_count["$title"]++))
  count=${title_count["$title"]}
  key="$title"
  (( count > 1 )) && key="$title [ws $ws #$count]"

  menu_to_workspace["$key"]="$ws"
  menu_to_icon["$key"]="$(get_icon "$class")"
done < <(hyprctl clients -j \
  | jq -r '.[] | select(.workspace.special != true) | "\(.title)\t\(.workspace.name // .workspace.id)\t\(.class)"')

# Feed fuzzel menu entries with icons
selected=$(for k in "${(@k)menu_to_workspace}"; do
  icon="${menu_to_icon[$k]}"
  printf '%s\0icon\x1f%s\n' "$k" "$icon"
done | fuzzel --dmenu)

# Dispatch to workspace
[[ -n "$selected" ]] && hyprctl dispatch workspace "${menu_to_workspace[$selected]}"
