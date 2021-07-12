#!/usr/bin/env bash

source "$PKG_PATH/../common/common.sh"

if [ "$SYSTEM" == "unknown" ]; then
    echo "Unknown operating system. Exiting."
    touch "$HOME/.ellipsis-unknown-system"
    exit 1
fi

pkg.install() {
    echo "$PKG_PATH" >> "$HOME/ellipsis_installed.log"
}

pkg.pull() {
    # Check for updates on git
    git remote update 2>&1 > /dev/null
    if git.is_behind; then
        # Pull down the updates
        git.pull
    fi

    echo "$PKG_PATH" >> "$HOME/ellipsis_updated.log"
}

pkg.uninstall() {
    echo "$PKG_PATH" >> "$HOME/ellipsis_uninstalled.log"
}
