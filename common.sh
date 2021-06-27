#!/usr/bin/env bash

function common_system() {
    KERNEL_VERSION=$(cat /proc/version)

    if [[ "$KERNEL_VERSION" == *"microsoft"* ]]; then
        echo "wsl"
    else
        echo "linux"
    fi
}

function common_link() {
    if [ -d "$PKG_PATH/files" ]; then
        fs.link_files "$PKG_PATH/files"
    fi

    if [ -d "$PKG_PATH/bin" ]; then
        fs.link_rfiles "$PKG_PATH/bin" "$HOME/bin"
    fi
}

function common_install() {
    if [ -f "$PKG_PATH/install.sh" ]; then
        bash "$PKG_PATH/install.sh" "$ELLIPSIS_SRC" "$PKG_PATH"
    fi

    if [ -f ".restart.lock" ]; then
        echo ""
        echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the installation.\e[0m"
        rm -rf .restart.lock
        exit 1
    fi
}

function common_pull() {
    # Unlink old files
    hooks.unlink

    # Pull package changes
    git.pull

    # Link new files
    pkg.link

    if [ -f "$PKG_PATH/update.sh" ]; then
        bash "$PKG_PATH/update.sh" "$ELLIPSIS_SRC" "$PKG_PATH"
    fi

    if [ -f ".restart.lock" ]; then
        echo ""
        echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the update.\e[0m"
        rm -rf .restart.lock
        exit 1
    fi
}

function common_uninstall() {
    if [ -f "$PKG_PATH/uninstall.sh" ]; then
        bash "$PKG_PATH/uninstall.sh" "$ELLIPSIS_SRC" "$PKG_PATH"
    fi

    if [ -f ".restart.lock" ]; then
        echo ""
        echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the uninstall.\e[0m"
        rm -rf .restart.lock
        exit 1
    fi
}