#!/bin/sh
set -e
src="$1"
patch=$(cd "$(dirname "$0")" && pwd)/$(basename "$0" .sh).patch

# Example Script


if [ -r "$patch" ]; then
    cd $src
    patch -p1 < "$patch"
fi

exit 0
