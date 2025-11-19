#!/bin/sh
set -e
src="$1"


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


# --- node_modules/@xterm/xterm/src/browser/services/SelectionService.ts.orig
# +++ node_modules/@xterm/xterm/src/browser/services/SelectionService.ts.new
# @@ -247,7 +247,7 @@
#      // Format string by replacing non-breaking space chars with regular spaces
#      // and joining the array into a multi-line string.
#      const formattedResult = result.map(line =>
# -      line.replace(ALL_NON_BREAKING_SPACE_REGEX, ' ')
# +      line.replace(ALL_NON_BREAKING_SPACE_REGEX, ' ').trimEnd()
#      ).join(Browser.isWindows ? '\r\n' : '\n');
#  
#      return formattedResult;


orig='return s.map((e=>e.replace(p," "))).join(d.isWindows?'
new='return s.map((e=>e.replace(p," ").trimEnd())).join(d.isWindows?'
file="$src/html/node_modules/@xterm/xterm/lib/xterm.js"

ret=0
ttyd-mod-scripts/fsed "$orig" "$new" "$file" || ret=$?
exit $ret
