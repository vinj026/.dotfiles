import os
import re

DIR = "/home/vin/.config/quickshell/components/bar"

def fix_file(filename):
    filepath = os.path.join(DIR, filename)
    if not os.path.isfile(filepath) or not filename.endswith(".qml"):
        return
        
    with open(filepath, "r") as f:
        content = f.read()

    blocks = content.split("Text {")
    new_blocks = [blocks[0]]
    
    for block in blocks[1:]:
        if '"Material Symbols Rounded"' in block:
            # It's an icon!
            if filename == "StartButton.qml":
                # Start button was originally lg
                block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.icon.lg', block)
            elif "MicIndicator" in filename:
                # Keep mic logic but revert sizes to what the user requested: mic not muted smaller, muted normal
                # Originally mic muted was `xl` or `md`? Let's just use original md for both since user wants the ORIGINAL configuration sizes as reference.
                block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.icon.md', block)
            else:
                block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.icon.md', block)
            
        elif "fontMono" in block or "font.family: C.Style.fontMono" in block:
            # It's a text value
            block = re.sub(r'font\.pixelSize:.*', 'font.pixelSize: C.Style.fs.sm', block)
            
        new_blocks.append(block)
        
    new_content = "Text {".join(new_blocks)
    
    with open(filepath, "w") as f:
        f.write(new_content)

for f in os.listdir(DIR):
    fix_file(f)
