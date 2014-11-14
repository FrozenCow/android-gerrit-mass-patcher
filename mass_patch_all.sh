#!/bin/bash
root="$(cd "$(dirname "$0")" && pwd)"
for rom in "$root/roms/*"
do
    "$root/mass_patch.sh" "$rom"
done