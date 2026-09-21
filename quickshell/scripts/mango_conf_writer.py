#!/usr/bin/env python3
"""
mango_conf_writer.py — Read/write values in MangoWM .conf files.

Usage:
  mango_conf_writer.py get  <file> <key>
  mango_conf_writer.py set  <file> <key> <value>
  mango_conf_writer.py dump <file>          # dump all key=value as JSON
"""
import sys
import os
import re
import json


def read_conf(path):
    """Parse a .conf file into an ordered list of (line, key, value) tuples."""
    lines = []
    try:
        with open(path, "r") as f:
            for line in f:
                stripped = line.rstrip("\n")
                # Match key=value, ignore comments and blanks
                m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", stripped)
                if m:
                    lines.append(("kv", stripped, m.group(1), m.group(2)))
                else:
                    lines.append(("raw", stripped, None, None))
    except FileNotFoundError:
        pass
    return lines


def get_value(path, key):
    lines = read_conf(path)
    for kind, raw, k, v in lines:
        if kind == "kv" and k == key:
            print(v)
            return
    print("")  # key not found → empty string


def set_value(path, key, value):
    lines = read_conf(path)
    found = False
    out = []
    for kind, raw, k, v in lines:
        if kind == "kv" and k == key:
            out.append(f"{key}={value}")
            found = True
        else:
            out.append(raw)
    if not found:
        out.append(f"{key}={value}")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print("OK")


def dump_conf(path):
    lines = read_conf(path)
    result = {}
    for kind, raw, k, v in lines:
        if kind == "kv":
            # Try numeric coercion
            try:
                result[k] = int(v)
                continue
            except ValueError:
                pass
            try:
                result[k] = float(v)
                continue
            except ValueError:
                pass
            result[k] = v
    print(json.dumps(result))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]
    path = sys.argv[2]

    if cmd == "get":
        if len(sys.argv) < 4:
            print("Usage: get <file> <key>")
            sys.exit(1)
        get_value(path, sys.argv[3])
    elif cmd == "set":
        if len(sys.argv) < 5:
            print("Usage: set <file> <key> <value>")
            sys.exit(1)
        set_value(path, sys.argv[3], sys.argv[4])
    elif cmd == "dump":
        dump_conf(path)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
