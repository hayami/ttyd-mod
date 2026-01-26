#!/bin/sh
set -e
src="$1"
patch=$(cd "$(dirname "$0")" && pwd)/$(basename "$0" .sh).patch

# In xterm.js with the WebLinksAddon enabled, left-clicking a URL opens
# it in the browser, but this conflicts with selecting a text area using
# the left mouse button, which is inconvenient. Therefore, left-clicks
# on links are now ignored when no modifier keys are pressed.


if [ -r "$patch" ]; then
    cd $src
    patch -p1 < "$patch"
fi

exit 0
