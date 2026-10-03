#!/usr/bin/env python3
import json
import os
import socket
import subprocess


def compact_workspaces():
    # Haal alle actieve workspaces op
    res = subprocess.run(
        ["hyprctl", "workspaces", "-j"], capture_output=True, text=True
    )
    if res.returncode != 0:
        return

    workspaces = json.loads(res.stdout)
    # Filter normale workspaces (> 0) en sorteer op huidig ID
    valid_ws = sorted([w for w in workspaces if w["id"] > 0], key=lambda x: x["id"])

    # Hernummer opeenvolgend vanaf 1
    for expected_id, ws in enumerate(valid_ws, start=1):
        current_id = ws["id"]
        if current_id != expected_id:
            subprocess.run(
                ["hyprctl", "dispatch", "change_id", str(current_id), str(expected_id)]
            )


def main():
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        return

    sock_path = f"/tmp/hypr/{signature}/.socket2.sock"
    if not os.path.exists(sock_path):
        sock_path = f"/run/user/{os.getuid()}/hypr/{signature}/.socket2.sock"

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock_path)

    compact_workspaces()

    while True:
        data = s.recv(1024).decode("utf-8", errors="ignore")
        if not data:
            break
        # Hernummer bij venster- of workspace-gebeurtenissen
        if any(
            evt in data
            for evt in ["openwindow", "closewindow", "movewindow", "destroyworkspace"]
        ):
            compact_workspaces()


if __name__ == "__main__":
    main()
