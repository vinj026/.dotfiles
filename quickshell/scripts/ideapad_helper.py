#!/usr/bin/env python3
"""
ideapad_helper.py — IdeaPad ACPI & Battery Hardware Controller
Detects sysfs paths dynamically, reads battery telemetry & health,
and toggles Lenovo IdeaPad features (Conservation Mode, Rapid Charge, Kbd Backlight).
"""

import os
import sys
import glob
import json
import subprocess

def find_first_existing(patterns):
    for pat in patterns:
        matches = glob.glob(pat)
        if matches:
            return matches[0]
    return None

def read_file(path):
    if not path or not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return None

def write_file(path, value):
    if not path or not os.path.exists(path):
        return False, f"Path does not exist: {path}"
    
    val_str = str(value).strip()
    # Try direct write
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(val_str + "\n")
        return True, "Direct write succeeded"
    except PermissionError:
        pass
    except Exception as e:
        return False, f"Write error: {e}"

    # Fallback to pkexec
    cmd = ["pkexec", "sh", "-c", f"printf '%s\\n' '{val_str}' > '{path}'"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if res.returncode == 0:
            return True, "pkexec write succeeded"
        return False, f"pkexec failed: {res.stderr.strip()}"
    except Exception as e:
        return False, f"Elevation failed: {e}"

class IdeapadSysfs:
    def __init__(self):
        # 1. Find battery path
        self.bat_path = find_first_existing([
            "/sys/class/power_supply/BAT1",
            "/sys/class/power_supply/BAT0",
            "/sys/class/power_supply/BAT*"
        ])

        # 2. Find conservation mode path
        self.conservation_path = find_first_existing([
            "/sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode",
            "/sys/devices/platform/VPC2004:00/conservation_mode",
            "/sys/devices/platform/PNP0C09:00/VPC2004:00/conservation_mode"
        ])

        # 3. Find charge_types path (modern Linux kernel Lenovo extension)
        self.charge_types_path = os.path.join(self.bat_path, "charge_types") if self.bat_path and os.path.exists(os.path.join(self.bat_path, "charge_types")) else None

        # 4. Find rapid charge path (older kernel)
        self.rapid_charge_path = find_first_existing([
            "/sys/bus/platform/drivers/ideapad_acpi/*/rapid_charge",
            "/sys/devices/platform/VPC2004:00/rapid_charge"
        ])

        # 5. Find keyboard backlight path
        self.kbd_path = find_first_existing([
            "/sys/class/leds/platform::kbd_backlight/brightness",
            "/sys/class/leds/*kbd*/brightness",
            "/sys/class/leds/*backlight*/brightness"
        ])
        self.kbd_max_path = None
        if self.kbd_path:
            dir_name = os.path.dirname(self.kbd_path)
            max_file = os.path.join(dir_name, "max_brightness")
            if os.path.exists(max_file):
                self.kbd_max_path = max_file

    def get_status(self):
        data = {
            "battery": {
                "present": False,
                "path": self.bat_path,
                "percentage": 0,
                "status": "Unknown",
                "is_charging": False,
                "health_percent": 100.0,
                "wear_percent": 0.0,
                "cycle_count": 0,
                "energy_full_mwh": 0.0,
                "energy_design_mwh": 0.0,
                "power_now_w": 0.0
            },
            "conservation_mode": {
                "supported": False,
                "path": self.conservation_path or self.charge_types_path,
                "enabled": False
            },
            "rapid_charge": {
                "supported": False,
                "path": self.charge_types_path or self.rapid_charge_path,
                "enabled": False
            },
            "kbd_backlight": {
                "supported": False,
                "path": self.kbd_path,
                "brightness": 0,
                "max_brightness": 0
            }
        }

        # Read Battery
        if self.bat_path and os.path.exists(self.bat_path):
            data["battery"]["present"] = True
            
            cap = read_file(os.path.join(self.bat_path, "capacity"))
            if cap is not None:
                data["battery"]["percentage"] = int(cap)

            stat = read_file(os.path.join(self.bat_path, "status"))
            if stat:
                data["battery"]["status"] = stat
                data["battery"]["is_charging"] = (stat.lower() == "charging")

            cycles = read_file(os.path.join(self.bat_path, "cycle_count"))
            if cycles is not None:
                data["battery"]["cycle_count"] = int(cycles)

            # Energy or Charge (for health/wear calculation)
            ef = read_file(os.path.join(self.bat_path, "energy_full"))
            efd = read_file(os.path.join(self.bat_path, "energy_full_design"))
            if ef is None:
                ef = read_file(os.path.join(self.bat_path, "charge_full"))
                efd = read_file(os.path.join(self.bat_path, "charge_full_design"))

            if ef and efd:
                try:
                    f_val = float(ef)
                    fd_val = float(efd)
                    data["battery"]["energy_full_mwh"] = round(f_val / 1000.0, 1)
                    data["battery"]["energy_design_mwh"] = round(fd_val / 1000.0, 1)
                    if fd_val > 0:
                        health = round((f_val / fd_val) * 100.0, 1)
                        data["battery"]["health_percent"] = min(100.0, health)
                        data["battery"]["wear_percent"] = max(0.0, round(100.0 - health, 1))
                except Exception:
                    pass

            p_now = read_file(os.path.join(self.bat_path, "power_now"))
            if p_now:
                try:
                    data["battery"]["power_now_w"] = round(float(p_now) / 1000000.0, 2)
                except Exception:
                    pass

        # Read Conservation Mode
        if self.conservation_path:
            data["conservation_mode"]["supported"] = True
            val = read_file(self.conservation_path)
            data["conservation_mode"]["enabled"] = (val == "1")
        elif self.charge_types_path:
            ct = read_file(self.charge_types_path) or ""
            if "Long_Life" in ct:
                data["conservation_mode"]["supported"] = True
                data["conservation_mode"]["enabled"] = ("[Long_Life]" in ct)

        # Read Rapid Charge
        if self.charge_types_path:
            ct = read_file(self.charge_types_path) or ""
            if "Fast" in ct:
                data["rapid_charge"]["supported"] = True
                data["rapid_charge"]["enabled"] = ("[Fast]" in ct)
        elif self.rapid_charge_path:
            data["rapid_charge"]["supported"] = True
            val = read_file(self.rapid_charge_path)
            data["rapid_charge"]["enabled"] = (val == "1")

        # Read Keyboard Backlight
        if self.kbd_path:
            data["kbd_backlight"]["supported"] = True
            b_val = read_file(self.kbd_path)
            if b_val is not None:
                data["kbd_backlight"]["brightness"] = int(b_val)
            if self.kbd_max_path:
                mb_val = read_file(self.kbd_max_path)
                if mb_val is not None:
                    data["kbd_backlight"]["max_brightness"] = int(mb_val)

        return data

    def set_conservation(self, enable: bool):
        success = False
        msg = ""
        if self.conservation_path:
            ok, err = write_file(self.conservation_path, "1" if enable else "0")
            if ok:
                success = True
            else:
                msg += f"conservation_mode write: {err}; "

        if self.charge_types_path:
            target = "Long_Life" if enable else "Standard"
            ok, err = write_file(self.charge_types_path, target)
            if ok:
                success = True
            else:
                msg += f"charge_types write: {err}; "

        return success, msg or ("OK" if success else "No conservation path found")

    def set_rapid(self, enable: bool):
        success = False
        msg = ""
        if self.charge_types_path:
            target = "Fast" if enable else "Standard"
            ok, err = write_file(self.charge_types_path, target)
            if ok:
                success = True
            else:
                msg += f"charge_types write: {err}; "
        elif self.rapid_charge_path:
            ok, err = write_file(self.rapid_charge_path, "1" if enable else "0")
            if ok:
                success = True
            else:
                msg += f"rapid_charge write: {err}; "

        return success, msg or ("OK" if success else "No rapid charge path found")

    def set_kbd(self, value: int):
        if not self.kbd_path:
            return False, "Keyboard backlight not supported on this hardware"
        return write_file(self.kbd_path, str(value))

def main():
    ctrl = IdeapadSysfs()

    if len(sys.argv) < 2 or sys.argv[1] == "status":
        print(json.dumps(ctrl.get_status(), indent=2))
        return

    cmd = sys.argv[1]
    if cmd == "set-conservation":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "error": "Missing argument: 1 or 0"}))
            sys.exit(1)
        en = sys.argv[2] in ["1", "true", "True", "on", "yes"]
        ok, reason = ctrl.set_conservation(en)
        print(json.dumps({"success": ok, "message": reason, "enabled": en}))
    elif cmd == "set-rapid":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "error": "Missing argument: 1 or 0"}))
            sys.exit(1)
        en = sys.argv[2] in ["1", "true", "True", "on", "yes"]
        ok, reason = ctrl.set_rapid(en)
        print(json.dumps({"success": ok, "message": reason, "enabled": en}))
    elif cmd == "set-kbd":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "error": "Missing argument: brightness value"}))
            sys.exit(1)
        try:
            val = int(sys.argv[2])
            ok, reason = ctrl.set_kbd(val)
            print(json.dumps({"success": ok, "message": reason, "value": val}))
        except ValueError:
            print(json.dumps({"success": False, "error": "Brightness must be an integer"}))
            sys.exit(1)
    else:
        print(json.dumps({"success": False, "error": f"Unknown command: {cmd}"}))
        sys.exit(1)

if __name__ == "__main__":
    main()
