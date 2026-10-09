pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isOpen: false
    property string targetMonitor: ""
    property bool grimReady: false
    property string fullScreenshot: ""
    property string cropJpg: ""
    property string lensHtml: ""
    
    // QR Code Result
    property string qrResult: ""
    property bool isQrUrl: false
    
    property bool isLoading: false

    function toggle(monitor) {
        if (monitor === undefined) monitor = "";
        if (isOpen) close();
        else open(monitor);
    }

    function open(monitor) {
        if (monitor === undefined) monitor = "";
        if (isOpen) return;
        targetMonitor = monitor;
        
        let ts = Date.now();
        fullScreenshot = Quickshell.cachePath(`search-full-${ts}.png`).toString().replace(/^file:\/\//, "");
        cropJpg = Quickshell.cachePath(`search-crop-${ts}.jpg`).toString().replace(/^file:\/\//, "");
        lensHtml = Quickshell.cachePath(`search-lens-${ts}.html`).toString().replace(/^file:\/\//, "");
        
        grimReady = false;
        qrResult = "";
        isQrUrl = false;
        isLoading = false;
        
        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        // Delay screenshot slightly to let Notch UI close and layout settle
        // Use grim -o to capture only the active screen so coordinates match
        let outputArg = targetMonitor ? `-o "${targetMonitor}"` : "";
        proc.command = ["bash", "-c", `sleep 0.3 && grim ${outputArg} "${fullScreenshot}"`];
        proc.exited.connect((code) => {
            if (code === 0) {
                root.grimReady = true;
                root.isOpen = true;
            }
            proc.destroy();
        });
        proc.running = true;
    }

    function close() {
        isOpen = false;
        grimReady = false;
        qrResult = "";
        
        // Clean up full screenshot immediately
        Quickshell.execDetached(["rm", "-f", fullScreenshot]);
        // Crop/Lens files might be in use by browser, clean them up after delay
        Quickshell.execDetached(["bash", "-c", `sleep 15 && rm -f "${cropJpg}" "${lensHtml}"`]);
    }

    function searchRegion(x, y, w, h) {
        isLoading = true;
        qrResult = "";
        
        let cropCmd = ["magick", fullScreenshot, "-crop", `${w}x${h}+${x}+${y}`, "-resize", "1000x1000>", "-strip", "-quality", "85", cropJpg];
        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        proc.command = cropCmd;
        proc.exited.connect((code) => {
            proc.destroy();
            if (code === 0) {
                checkQrCode();
            } else {
                isLoading = false;
            }
        });
        proc.running = true;
    }

    function checkQrCode() {
        let qrProc = Qt.createQmlObject('import Quickshell.Io; Process { property string outputText: "" }', root);
        qrProc.command = ["zbarimg", "--raw", "-q", cropJpg];
        
        qrProc.stdout = Qt.createQmlObject('import Quickshell.Io; SplitParser { onRead: data => { parent.outputText += data; } }', qrProc);
        
        qrProc.exited.connect((code) => {
            let output = qrProc.outputText.trim();
            if (code === 0 && output.length > 0) {
                // QR detected!
                qrResult = output;
                isQrUrl = output.startsWith("http://") || output.startsWith("https://");
                isLoading = false;
            } else {
                // No QR, send to Lens directly
                sendToLens();
            }
            qrProc.destroy();
        });
        qrProc.running = true;
    }

    function sendToLens() {
        let b64Proc = Qt.createQmlObject('import Quickshell.Io; Process { property string b64Text: "" }', root);
        b64Proc.command = ["bash", "-c", `base64 -w0 "${cropJpg}" 2>/dev/null || base64 -b0 "${cropJpg}"`];
        
        b64Proc.stdout = Qt.createQmlObject('import Quickshell.Io; SplitParser { onRead: data => { parent.b64Text += data; } }', b64Proc);
        
        b64Proc.exited.connect((code) => {
            let b64 = b64Proc.b64Text;
            if (code === 0 && b64.length > 0) {
                buildAndOpenLensHtml(b64);
            }
            isLoading = false;
            close();
            b64Proc.destroy();
        });
        b64Proc.running = true;
    }
    
    function buildAndOpenLensHtml(b64) {
        const buildHtml = [
            `echo '<html><body style="margin:0;display:flex;justify-content:center;align-items:center;height:100vh;background:#111;color:#fff;font-family:system-ui"><p>Searching with Google Lens…</p><form id="f" method="POST" enctype="multipart/form-data" action="https://lens.google.com/v3/upload"></form><script>'`,
            `echo "var b=atob('${b64}');"`,
            `echo 'var a=new Uint8Array(b.length);for(var i=0;i<b.length;i++)a[i]=b.charCodeAt(i);var d=new DataTransfer();d.items.add(new File([a],"i.jpg",{type:"image/jpeg"}));var inp=document.createElement("input");inp.type="file";inp.name="encoded_image";inp.files=d.files;document.getElementById("f").appendChild(inp);document.getElementById("f").submit();'`,
            `echo '</script></body></html>'`
        ].join(" ; ");
        
        Quickshell.execDetached(["bash", "-c", `{ ${buildHtml} ; } > "${lensHtml}" && xdg-open "${lensHtml}"`]);
    }
}
