import os
import re

DIR = "/home/vin/.config/quickshell/components/bar"

sizes = {
    "StartButton.qml": "C.Style.icon.lg",
    "RamIndicator.qml": "C.Style.icon.sm",
    "TempIndicator.qml": "C.Style.icon.sm",
    "Network.qml": "C.Style.icon.xl",
    "MicIndicator.qml": "C.Audio.micMuted ? C.Style.icon.xl : C.Style.icon.xs",
    "Volume.qml": "C.Style.icon.xl",
    "Battery.qml": "C.Style.icon.sm",
    "NotifIndicator.qml": "C.Style.icon.sm"
}

def fix_file(filename):
    if filename not in sizes:
        return
        
    filepath = os.path.join(DIR, filename)
    with open(filepath, "r") as f:
        content = f.read()

    blocks = content.split("Text {")
    new_blocks = [blocks[0]]
    
    for block in blocks[1:]:
        if '"Material Symbols Rounded"' in block:
            block = re.sub(r'font\.pixelSize:.*', f'font.pixelSize: {sizes[filename]}', block)
            
        elif "fontMono" in block or "font.family: C.Style.fontMono" in block:
            block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.fs.sm', block)
            
        new_blocks.append(block)
        
    new_content = "Text {".join(new_blocks)
    
    with open(filepath, "w") as f:
        f.write(new_content)

for f in sizes.keys():
    fix_file(f)
