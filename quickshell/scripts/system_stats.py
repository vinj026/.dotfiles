#!/usr/bin/env python3
import os, time, json

state_file = "/tmp/qs_sys_stats_state.json"
now = time.time()

# 1. Read current CPU
cpu_idle = 0
cpu_total = 0
try:
    with open("/proc/stat") as f:
        fields = [float(x) for x in f.readline().split()[1:8]]
        cpu_idle = fields[3] + fields[4]
        cpu_total = sum(fields)
except:
    pass

# 2. Read Network bytes (sum of non-loopback)
net_rx = 0
net_tx = 0
try:
    with open("/proc/net/dev") as f:
        for line in f:
            if ":" in line:
                iface, data = line.split(":", 1)
                iface = iface.strip()
                if iface != "lo":
                    vals = data.split()
                    net_rx += int(vals[0])
                    net_tx += int(vals[8])
except:
    pass

# Read previous state
prev = {}
if os.path.exists(state_file):
    try:
        with open(state_file) as f:
            prev = json.load(f)
    except:
        pass

dt = max(0.5, now - prev.get("time", now - 1.0))
d_cpu_total = max(1.0, cpu_total - prev.get("cpu_total", cpu_total - 100))
d_cpu_idle = max(0.0, cpu_idle - prev.get("cpu_idle", cpu_idle - 50))
cpu_pct = round(max(0.0, min(100.0, (1.0 - d_cpu_idle / d_cpu_total) * 100)))

rx_rate = max(0.0, (net_rx - prev.get("net_rx", net_rx)) / dt)
tx_rate = max(0.0, (net_tx - prev.get("net_tx", net_tx)) / dt)

def fmt_speed(bps):
    if bps >= 1048576:
        return f"{bps / 1048576:.1f} MB/s"
    elif bps >= 1024:
        return f"{bps / 1024:.0f} KB/s"
    return f"{bps:.0f} B/s"

# Save new state
try:
    with open(state_file, "w") as f:
        json.dump({"time": now, "cpu_total": cpu_total, "cpu_idle": cpu_idle, "net_rx": net_rx, "net_tx": net_tx}, f)
except:
    pass

# 3. Memory & Swap
mem = {}
try:
    with open("/proc/meminfo") as f:
        for line in f:
            p = line.split(":")
            if len(p) == 2:
                mem[p[0].strip()] = int(p[1].split()[0])
except:
    pass
total_ram = mem.get("MemTotal", 1)
avail_ram = mem.get("MemAvailable", 0)
used_ram = total_ram - avail_ram
ram_pct = round((used_ram / total_ram) * 100)
ram_str = f"{used_ram / 1048576:.1f}/{total_ram / 1048576:.1f} GB"

total_swap = mem.get("SwapTotal", 0)
free_swap = mem.get("SwapFree", 0)
used_swap = total_swap - free_swap
swap_pct = round((used_swap / max(1, total_swap)) * 100) if total_swap > 0 else 0

# 4. Temperature
temp = 45
try:
    for t in os.listdir("/sys/class/thermal"):
        if t.startswith("thermal_zone"):
            with open(f"/sys/class/thermal/{t}/temp") as f:
                val = int(f.read().strip()) / 1000
                if 20 < val < 110:
                    temp = round(val)
                    break
except:
    pass

# 5. Battery
bat_pct = 100
bat_w = 0.0
bat_status = "Full"
try:
    for b in os.listdir("/sys/class/power_supply"):
        if b.startswith("BAT"):
            with open(f"/sys/class/power_supply/{b}/capacity") as f:
                bat_pct = int(f.read().strip())
            with open(f"/sys/class/power_supply/{b}/status") as f:
                bat_status = f.read().strip()
            if os.path.exists(f"/sys/class/power_supply/{b}/power_now"):
                with open(f"/sys/class/power_supply/{b}/power_now") as f:
                    bat_w = round(int(f.read().strip()) / 1000000.0, 1)
            break
except:
    pass

print(json.dumps({
    "cpu_pct": cpu_pct,
    "temp": temp,
    "ram_pct": ram_pct,
    "ram_str": ram_str,
    "swap_pct": swap_pct,
    "rx_str": fmt_speed(rx_rate),
    "tx_str": fmt_speed(tx_rate),
    "bat_pct": bat_pct,
    "bat_w": bat_w,
    "bat_status": bat_status
}))
