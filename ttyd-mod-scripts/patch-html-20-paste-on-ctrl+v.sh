#!/bin/sh
set -e
src="$1"

# Enable Ctrl+V to paste clipboard text. Tested with the following browsers.
#   - Mozilla Firefox for Linux
#   - Google Chrome for Linux


cd $src
patch -p1 << 'EOF'
--- a/html/src/components/terminal/xterm/index.ts
+++ b/html/src/components/terminal/xterm/index.ts
@@ -455,6 +455,12 @@ export class Xterm {
                             break;
                     }
                     break;
+                case 'enablePasteOnCtrlV':
+                    if (value) {
+                        const enabled = this.enablePasteOnCtrlV();
+                        if (enabled) console.log('[ttyd-mod] paste on Ctrl+V enabled');
+                    }
+                    break;
                 default:
                     console.log(`[ttyd] option: ${key}=${JSON.stringify(value)}`);
                     if (terminal.options[key] instanceof Object) {
@@ -532,4 +538,75 @@ export class Xterm {
                 break;
         }
     }
+
+    @bind
+    private enablePasteOnCtrlV(): boolean {
+        const { terminal } = this;
+
+        const isCtrlV = (e: KeyboardEvent): boolean =>
+            e.ctrlKey &&
+            !e.shiftKey &&
+            !e.altKey &&
+            !e.metaKey &&
+            (e.code === 'KeyV' || e.key.toLowerCase() === 'v') &&
+            e.type === 'keydown' &&
+            !e.repeat &&
+            !e.isComposing;
+
+        terminal.attachCustomKeyEventHandler((e: KeyboardEvent): boolean => {
+            // In the case of Firefox, if false is returned here when
+            // Ctrl+V is pressed, Firefox would paste by itself. Other
+            // conditions also required, such as e.preventDefault() not
+            // being called inside the keydown event handlers.
+
+            // returns whether the event should be processed by xterm.js
+            return !isCtrlV(e);
+        });
+        document.addEventListener('keydown', pasteHandler, { capture: false });
+        return true;
+
+        function pasteHandler(e: KeyboardEvent): void {
+            if (isCtrlV(e)) {
+                const ua = navigator.userAgent;
+                if (ua.includes('Firefox')) return firefox(e);
+                if (ua.includes('Chrome')) return chromium(e);
+                if (ua.includes('Chromium')) return chromium(e);
+                console.log('[ttyd-mod] browser is not supported: ' + ua);
+            }
+            return;
+
+            function firefox(e) {
+                void e;
+                return;
+            }
+
+            function chromium(e) {
+                withTimeout(navigator.clipboard.readText())
+                    .then((text: string) => {
+                        if (text) terminal.paste(text);
+                    })
+                    .catch(err => {
+                        console.error('[ttyd-mod] readText():', err);
+                    });
+                e.preventDefault();
+                return;
+            }
+
+            // Timeout Helper
+            function withTimeout<T>(p: Promise<T>, ms = 200): Promise<T> {
+                return new Promise<T>((resolve, reject) => {
+                    const id = setTimeout(() => {
+                        reject(new Error('timeout'));
+                    }, ms);
+                    p.then(v => {
+                        clearTimeout(id);
+                        resolve(v);
+                    }).catch(e => {
+                        clearTimeout(id);
+                        reject(e);
+                    });
+                });
+            }
+        }
+    }
 }
EOF

exit 0
