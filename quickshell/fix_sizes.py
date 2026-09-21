import os
import re

DIR = "/home/vin/.config/quickshell/components/bar"

def fix_file(filename):
    filepath = os.path.join(DIR, filename)
    if not os.path.isfile(filepath) or not filename.endswith(".qml"):
        return
        
    with open(filepath, "r") as f:
        content = f.read()

    # Standardize icon sizes
    # First, find Text elements that use Material Symbols Rounded
    # We will just replace `font.pixelSize: ...` with `font.pixelSize: C.Style.icon.lg`
    # inside blocks that contain `font.family: "Material Symbols Rounded"`
    
    blocks = content.split("Text {")
    new_blocks = [blocks[0]]
    
    for block in blocks[1:]:
        if '"Material Symbols Rounded"' in block:
            # It's an icon!
            if "MicIndicator" in filename:
                # keep mic logic: C.Audio.micMuted ? C.Style.icon.lg : C.Style.icon.sm
                block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Audio.micMuted ? C.Style.icon.lg : C.Style.icon.sm', block)
            else:
                block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.icon.lg', block)
            
        elif "fontMono" in block or "font.family: C.Style.fontMono" in block:
            # It's a text value
            block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.fs.sm', block)
            
        new_blocks.append(block)
        
    new_content = "Text {".join(new_blocks)
    
    with open(filepath, "w") as f:
        f.write(new_content)

for f in os.listdir(DIR):
    fix_file(f)
