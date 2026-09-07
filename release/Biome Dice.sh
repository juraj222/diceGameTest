#!/bin/sh
printf '\033c\033]0;%s\a' Biome Dice
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Biome Dice.x86_64" "$@"
