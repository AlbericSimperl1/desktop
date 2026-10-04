#!/usr/bin/env bash

# Toggle Quickshell via ipc/signal (of een custom Quickshell target)
# Als Quickshell runt als proces, kun je een signaal of IPC-call sturen,
# of de layer/window hide command gebruiken.
quickshell msg "bar.visible = !bar.visible" 2>/dev/null || true

# Toggle Hyprspace overview
hyprctl dispatch overview:toggle
