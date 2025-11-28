#!/bin/sh
set -e
src="$1"

# Strip trailing whitespace when the selected text region is placed into
# the clipboard.


# colorcolumn adds trailing whitespace to any multiline copy-pasted content #332
# https://github.com/vim/vim/issues/332
# https://github.com/neovim/neovim/issues/1995
#
#  > What steps will reproduce the problem?
#  > 1. Add `set cc=80` to your ~/.vimrc
#  > 2. Open any document (e.g., ~/.vimrc)
#  > 3. Copy-and-paste code from there (e.g., into the same file)
#  >
#  > You'll find that each copy-and-pasted line has trailing whitespace,
#  > namely the space from the last character in a line to the color column.
#  >
#  > This only occurs with vim, not gvim.

cd $src
patch -p1 << 'EOF'
--- a/html/src/components/terminal/xterm/index.ts
+++ b/html/src/components/terminal/xterm/index.ts
@@ -91,6 +91,7 @@ export class Xterm {
     private webglAddon?: WebglAddon;
     private canvasAddon?: CanvasAddon;
     private zmodemAddon?: ZmodemAddon;
+    private container?: HTMLElement;
 
     private socket?: WebSocket;
     private token: string;
@@ -153,6 +154,7 @@ export class Xterm {
 
     @bind
     public open(parent: HTMLElement) {
+        this.container = parent;
         this.terminal = new Terminal(this.options.termOptions);
         const { terminal, fitAddon, overlayAddon, clipboardAddon, webLinksAddon } = this;
         window.term = terminal as TtydTerminal;
@@ -461,6 +463,12 @@ export class Xterm {
                         if (enabled) console.log('[ttyd-mod] paste on Ctrl+V enabled');
                     }
                     break;
+                case 'enableTrimSelection':
+                    if (value) {
+                        const enabled = this.enableTrimSelection();
+                        if (enabled) console.log('[ttyd-mod] trim selection enabled');
+                    }
+                    break;
                 default:
                     console.log(`[ttyd] option: ${key}=${JSON.stringify(value)}`);
                     if (terminal.options[key] instanceof Object) {
@@ -609,4 +617,31 @@ export class Xterm {
             }
         }
     }
+
+    @bind
+    private enableTrimSelection(): boolean {
+        const { terminal } = this;
+
+        const textarea = this.container?.querySelector('.xterm-helper-textarea') as HTMLTextAreaElement | null;
+        if (!textarea) {
+            console.error('[tty-mod] no textarea found');
+            return false;
+        }
+        textarea.addEventListener('copy', selectionHandler, { capture: false });
+        return true;
+
+        function selectionHandler(e: ClipboardEvent): void {
+            const data = e.clipboardData;
+            const orig = terminal.getSelection();
+            if (!data || !orig) return;
+            data.setData('text/plain', trimLines(orig));
+            e.preventDefault();
+            e.stopImmediatePropagation();
+        }
+
+        function trimLines(lines: string): string {
+            // Trim trailing whitespace on each line
+            return lines.replace(/[^\S\r\n]+(?=[\r\n]|$)/g, '');
+        }
+    }
 }
EOF
exit 0


# # --- node_modules/@xterm/xterm/src/browser/services/SelectionService.ts.orig
# # +++ node_modules/@xterm/xterm/src/browser/services/SelectionService.ts.new
# # @@ -247,7 +247,7 @@
# #      // Format string by replacing non-breaking space chars with regular spaces
# #      // and joining the array into a multi-line string.
# #      const formattedResult = result.map(line =>
# # -      line.replace(ALL_NON_BREAKING_SPACE_REGEX, ' ')
# # +      line.replace(ALL_NON_BREAKING_SPACE_REGEX, ' ').trimEnd()
# #      ).join(Browser.isWindows ? '\r\n' : '\n');
# #
# #      return formattedResult;
#
#
# orig='return s.map((e=>e.replace(p," "))).join(d.isWindows?'
# new='return s.map((e=>e.replace(p," ").trimEnd())).join(d.isWindows?'
# file="$src/html/node_modules/@xterm/xterm/lib/xterm.js"
#
# ret=0
# ttyd-mod-scripts/fsed "$orig" "$new" "$file" || ret=$?
# exit $ret
