#!/usr/bin/env bash

source "$PKG_PATH/../common/common.sh"

ELLIPSIS_PACKAGE=$(pkg.name_from_path "$PKG_PATH")

MISSING_HARD_DEPENDENCIES=0
common_hard_dependencies_check "$ELLIPSIS_PACKAGE"
common_soft_dependencies_check "$ELLIPSIS_PACKAGE"

PACKAGE_HAS_UPDATES=0

pkg.link() {
    if [ "$MISSING_HARD_DEPENDENCIES" == "0" ]; then
        common_link
    else
        echo "Missing dependencies - not linking."
    fi
}

pkg.install() {
    if [ "$MISSING_HARD_DEPENDENCIES" == "0" ]; then
        common_install
    else
        echo "Missing dependencies - not installing."
    fi
}

pkg.pull() {
    common_pull
    if [ "$MISSING_HARD_DEPENDENCIES" == "0" ]; then
        if [ "$PACKAGE_HAS_UPDATES" == "1" ]; then
            common_update
        fi
    else
        echo "Missing dependencies - not updating."
    fi
}

pkg.uninstall() {
    common_uninstall
}
