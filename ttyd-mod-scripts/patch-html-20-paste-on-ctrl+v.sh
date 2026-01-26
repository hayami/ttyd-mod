#!/bin/sh
set -e
src="$1"
patch=$(cd "$(dirname "$0")" && pwd)/$(basename "$0" .sh).patch

# Enable Ctrl+V to paste clipboard text. Tested with the following browsers.
#   - Mozilla Firefox for Linux
#   - Google Chrome for Linux


if [ -r "$patch" ]; then
    cd $src
    patch -p1 < "$patch"
fi

exit 0
