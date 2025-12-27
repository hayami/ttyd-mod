#!/bin/sh
set -e
src="$1"

# Strip trailing whitespace when the selected text region is placed into
# the clipboard.


# Details of What I Want to Do
# ----------------------------
#
# *** 1. First, at the source code level, the changes would be as follows.
#
#       --- node_modules/@xterm/xterm/src/browser/services/SelectionService.ts.orig
#       +++ node_modules/@xterm/xterm/src/browser/services/SelectionService.ts.new
#       @@ -247,9 +247,9 @@
#             // Format string by replacing non-breaking space chars with regular spaces
#             // and joining the array into a multi-line string.
#             const formattedResult = result.map(line =>
#               line.replace(ALL_NON_BREAKING_SPACE_REGEX, ' ')
#             ).join(Browser.isWindows ? '\r\n' : '\n');
#
#        -    return formattedResult;
#        +    return ((f,v) => f ? f(v) : v)(window.term?.trimSelection, formattedResult);
#           }
#
#
# *** 2. To do so, the following changes would be made to the minified code.
#
#       - return s.map((e=>e.replace(p," "))).join(d.isWindows?"\r\n":"\n")
#       + return ((f,v)=>f?f(v):v)(window.term?.trimSelection, s.map((e=>e.replace(p," "))).join(d.isWindows?"\r\n":"\n"))
#
#
# *** 3. Below is the script that makes the replacement described in 2.

target="$src/html/node_modules/@xterm/xterm/lib/xterm.js"


perl5verified=
for i in ${perl5:-$(which perl5 perl | grep '^/')}; do
    if "$i" -v < /dev/null 2>&1 | grep --quiet "^This is perl 5,"; then
        perl5verified="$i"
        break
    fi
done
if [ -z "$perl5verified" ]; then
    echo "ERROR: perl5 not found" 1>&2
    exit 1
fi
perl5="$perl5verified"


# foo.map(〜(balanced parentheses)〜)
pcre_map='([a-zA-Z_\$][a-zA-Z0-9_\$]*[.]map[(]((?:[^()]+|\((?2)\))*)[)])'

# .join(〜.isWindows?〜)
pcre_join='([.]join[(][^()]+[.]isWindows[?][^()]+[)])'

#      \1↴       \3↴
pcre="${pcre_map}${pcre_join}"

# PCRE substitution operator
sop='s/'"$pcre"'/((f,v)=>f?f(v):v)(window.term?.trimSelection,\1\3)/'

# Verify that the substitution has not been done
ret=$($perl5 -0777 -ne '
    $count += s/\Qwindow.term?.trimSelection\E//g;
    END { print "$count\n" }
' < $target)
if [ "$ret" != "0" ]; then
    echo "ERROR: Already substituted" 1>&2
    exit 1
fi

# Verify that the substitution occurs only once
ret=$($perl5 -0777 -ne '
    $count += '"$sop"';
    END { print "$count\n" }
' < $target)
if [ "$ret" != "1" ]; then
    echo "ERROR: Expected exactly one substitution location" 1>&2
    exit 1
fi

# Apply the substitution now
$perl5 -i -0777 -pe "$sop" $target


#
# *** 4. In index.ts, provide the function (trimSelection) introduced in 2.

cd $src
patch -p1 << 'EOF'
--- a/html/src/components/terminal/xterm/index.ts
+++ b/html/src/components/terminal/xterm/index.ts
@@ -15,6 +15,7 @@ import '@xterm/xterm/css/xterm.css';
 
 interface TtydTerminal extends Terminal {
     fit(): void;
+    trimSelection(selection: string): string;
 }
 
 declare global {
@@ -159,6 +160,7 @@ export class Xterm {
         window.term.fit = () => {
             this.fitAddon.fit();
         };
+        window.term.trimSelection = str => str; // do nothing by default
 
         terminal.loadAddon(fitAddon);
         terminal.loadAddon(overlayAddon);
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
@@ -609,4 +617,13 @@ export class Xterm {
             }
         }
     }
+
+    @bind
+    private enableTrimSelection(): boolean {
+        window.term.trimSelection = selection => {
+            // Trim trailing whitespace on each line
+            return selection.replace(/[^\S\r\n]+(?=[\r\n]|$)/g, '');
+        };
+        return true;
+    }
 }
EOF

exit 0


#
# *** 5. The following post motivated me to implement this feature.
#
#     https://github.com/vim/vim/issues/332
#     https://github.com/neovim/neovim/issues/1995
#     > colorcolumn adds trailing whitespace to any multiline copy-pasted content #332
#     >
#     >  > What steps will reproduce the problem?
#     >  > 1. Add `set cc=80` to your ~/.vimrc
#     >  > 2. Open any document (e.g., ~/.vimrc)
#     >  > 3. Copy-and-paste code from there (e.g., into the same file)
#     >  >
#     >  > You'll find that each copy-and-pasted line has trailing whitespace,
#     >  > namely the space from the last character in a line to the color column.
#     >  >
#     >  > This only occurs with vim, not gvim.
