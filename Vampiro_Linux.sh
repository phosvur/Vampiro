#!/bin/sh
printf '\033c\033]0;%s\a' Vampiro
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Vampiro_Linux.x86_64" "$@"
