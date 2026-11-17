#!/usr/bin/env bash
# print current workspace id only
hyprctl activeworkspace 2>/dev/null | sed -n 's/^workspace ID \([0-9]*\).*/\1/p' | head -n1
