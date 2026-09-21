#!/usr/bin/env python3
import os
import json

dirs = [
    os.path.expanduser("~/.dotfiles/mango/wallpaper"),
    os.path.expanduser("~/Pictures/Wallpapers")
]
curr_link = os.path.expanduser("~/.config/mango/wallpaper/current.jpg")
curr_path = os.path.realpath(curr_link) if os.path.exists(curr_link) else ""

files = []
seen = set()
for d in dirs:
    if os.path.isdir(d):
        for f in sorted(os.listdir(d)):
            if f.startswith("current."):
                continue
            ext = os.path.splitext(f)[1].lower()
            if ext in [".jpg", ".jpeg", ".png", ".webp"]:
                real = os.path.realpath(os.path.join(d, f))
                name = os.path.basename(real)
                if real not in seen and name not in seen:
                    seen.add(real)
                    seen.add(name)
                    files.append({
                        "path": real,
                        "name": name,
                        "title": os.path.splitext(name)[0].replace("-", " ").replace("_", " ").title(),
                        "isCurrent": real == curr_path
                    })

output_json = json.dumps(files, indent=2)

cache_dir = os.path.expanduser("~/.cache/quickshell")
os.makedirs(cache_dir, exist_ok=True)
cache_file = os.path.join(cache_dir, "wallpapers.json")
try:
    with open(cache_file, "w") as out:
        out.write(output_json)
except Exception:
    pass

print(output_json)
