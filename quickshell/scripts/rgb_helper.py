#!/usr/bin/env python3
"""
rgb_helper.py — Lenovo IdeaPad / Legion 4-Zone RGB Keyboard Controller
Wraps loq-rgb binary and persists state in rgb_state.json
"""

import os
import sys
import json
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOQ_RGB_BIN = os.path.join(SCRIPT_DIR, "loq-rgb", "bin", "loq-rgb")
STATE_FILE = os.path.join(SCRIPT_DIR, "rgb_state.json")

DEFAULT_STATE = {
    "supported": True,
    "power": True,
    "mode": "wave",
    "speed": 1,
    "brightness": "high",
    "zones": ["#00d4ff", "#00d4ff", "#00d4ff", "#00d4ff"],
    "error": None
}

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                s = json.load(f)
                return {**DEFAULT_STATE, **s}
        except Exception:
            pass
    return DEFAULT_STATE.copy()

def save_state(s):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(s, f, indent=2)
    except Exception as e:
        pass

def apply_rgb(state):
    if not os.path.exists(LOQ_RGB_BIN):
        state["error"] = "loq-rgb binary not found"
        return False

    mode = state.get("mode", "static")
    brightness = state.get("brightness", "high")
    speed = state.get("speed", 1)
    zones = state.get("zones", ["#ffffff"] * 4)
    power = state.get("power", True)

    if not power or brightness == "off":
        mode = "static"
        zones = ["#000000", "#000000", "#000000", "#000000"]
        b_arg = "low"
    else:
        b_arg = "high" if brightness == "high" else "low"

    cmd = [
        LOQ_RGB_BIN,
        f"--mode={mode}",
        f"--brightness={b_arg}",
        f"--speed={speed}",
        f"--zone1={zones[0]}",
        f"--zone2={zones[1]}",
        f"--zone3={zones[2]}",
        f"--zone4={zones[3]}"
    ]

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            state["error"] = None
            return True
    except Exception:
        pass

    # Try pkexec if direct failed
    pk_cmd = ["pkexec"] + cmd
    try:
        res = subprocess.run(pk_cmd, capture_output=True, text=True, timeout=4)
        if res.returncode == 0:
            state["error"] = None
            return True
        state["error"] = "Permission denied. Install 99-lenovo-rgb.rules to /etc/udev/rules.d/"
        return False
    except Exception as e:
        state["error"] = f"Failed to execute: {e}"
        return False

def main():
    state = load_state()

    if len(sys.argv) < 2 or sys.argv[1] == "status":
        print(json.dumps(state, indent=2))
        return

    action = sys.argv[1]

    if action == "toggle-power":
        state["power"] = not state.get("power", True)
        apply_rgb(state)
        save_state(state)
        print(json.dumps({"success": True, "state": state}))
    elif action == "set-mode":
        if len(sys.argv) > 2:
            m = sys.argv[2].lower()
            if m in ["static", "breath", "wave", "smooth"]:
                state["mode"] = m
                state["power"] = True
                apply_rgb(state)
                save_state(state)
        print(json.dumps({"success": True, "state": state}))
    elif action == "set-brightness":
        if len(sys.argv) > 2:
            b = sys.argv[2].lower()
            if b in ["off", "low", "high"]:
                state["brightness"] = b
                if b == "off":
                    state["power"] = False
                else:
                    state["power"] = True
                apply_rgb(state)
                save_state(state)
        print(json.dumps({"success": True, "state": state}))
    elif action == "set-speed":
        if len(sys.argv) > 2:
            try:
                spd = int(sys.argv[2])
                state["speed"] = max(1, min(4, spd))
                apply_rgb(state)
                save_state(state)
            except ValueError:
                pass
        print(json.dumps({"success": True, "state": state}))
    elif action == "set-color":
        if len(sys.argv) > 2:
            color = sys.argv[2].strip()
            if not color.startswith("#"):
                color = "#" + color
            state["mode"] = "static"
            state["power"] = True
            state["zones"] = [color, color, color, color]
            apply_rgb(state)
            save_state(state)
        print(json.dumps({"success": True, "state": state}))
    elif action == "set-zone":
        if len(sys.argv) > 3:
            try:
                z_idx = int(sys.argv[2]) - 1
                color = sys.argv[3].strip()
                if not color.startswith("#"):
                    color = "#" + color
                if 0 <= z_idx < 4:
                    state["mode"] = "static"
                    state["power"] = True
                    state["zones"][z_idx] = color
                    apply_rgb(state)
                    save_state(state)
            except ValueError:
                pass
        print(json.dumps({"success": True, "state": state}))
    else:
        print(json.dumps({"success": False, "error": f"Unknown command {action}"}))

if __name__ == "__main__":
    main()
