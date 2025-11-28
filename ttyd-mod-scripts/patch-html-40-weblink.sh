#!/bin/sh
set -e
src="$1"

# Left-clicking a URL opens it in the browser, but this conflicts with
# selecting a text area with the left mouse button. This is inconvenient.
# Therefore, left-clicks on links are now ignored when no modifier keys
# are pressed.


cd $src
patch -p1 << 'EOF'
--- a/html/src/components/terminal/xterm/index.ts
+++ b/html/src/components/terminal/xterm/index.ts
@@ -87,7 +87,7 @@ export class Xterm {
     private fitAddon = new FitAddon();
     private overlayAddon = new OverlayAddon();
     private clipboardAddon = new ClipboardAddon();
-    private webLinksAddon = new WebLinksAddon();
+    private webLinksAddon = new WebLinksAddon(this.webLinkHandler);
     private webglAddon?: WebglAddon;
     private canvasAddon?: CanvasAddon;
     private zmodemAddon?: ZmodemAddon;
@@ -644,4 +644,22 @@ export class Xterm {
             return lines.replace(/[^\S\r\n]+(?=[\r\n]|$)/g, '');
         }
     }
+
+    @bind
+    private webLinkHandler(e: MouseEvent, uri: string): void {
+        const noModifierKey = !e.shiftKey && !e.ctrlKey && !e.altKey && !e.metaKey;
+        if (noModifierKey) return;
+
+        const newWindow = window.open();
+        if (newWindow) {
+            try {
+                newWindow.opener = null;
+            } catch {
+                // no-op, Electron can throw
+            }
+            newWindow.location.href = uri;
+        } else {
+            console.warn('[ttyd-mod] Opening link blocked as opener could not be cleared');
+        }
+    }
 }
EOF
exit 0
