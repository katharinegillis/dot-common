#!/usr/bin/env bash

function common_system() {
    KERNEL_VERSION=$(cat /proc/version)

    if [ "$OSTYPE" == "linux-gnu" ]; then
        if [[ "$KERNEL_VERSION" == *"microsoft"* ]]; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [ "$OSTYPE" == "darwin" ]; then
        echo "mac"
    else
        echo "unknown"
    fi
}

SYSTEM=$(common_system)

function common_set_mode() {
    MODE="home"
    if [ ! -f "$HOME/.ellipsis-desktop-mode" ]; then
        echo "Install home dotfiles or work dotfiles? [home/work]: "
        read var
        if [ "$var" != "home" ] && [ "$var" != "work" ]; then
            echo "Invalid selection - please enter home or work on your next attempt. Exiting."
            exit 1
        fi

        echo "$var" > "$HOME/.ellipsis-desktop-mode"
    fi
}

function common_get_mode() {
    cat "$HOME/.ellipsis-desktop-mode"
}

common_set_mode

MODE=$(common_get_mode)

function common_link() {
    if [ -d "$PKG_PATH/files" ]; then
        fs.link_files "$PKG_PATH/files"
    fi

    if [ -d "$PKG_PATH/bin" ]; then
        echo "linking bin files"
        if [ ! -d "$HOME/bin" ]; then
            mkdir "$HOME/bin"
        fi
        fs.link_rfiles "$PKG_PATH/bin" "$HOME/bin"
    fi

    if [ "$SYSTEM" == "wsl" ]; then
        if [ -d "$PKG_PATH/files-wsl" ]; then
            fs.link_files "$PKG_PATH/files-wsl"
        fi

        if [ -d "$PKG_PATH/bin-wsl" ]; then
            if [ ! -d "$HOME/bin" ]; then
                mkdir "$HOME/bin"
            fi
            fs.link_rfiles "$PKG_PATH/bin-wsl" "$HOME/bin"
        fi
    fi

    if [ "$SYSTEM" == "linux" ]; then
        if [ -d "$PKG_PATH/files-linux" ]; then
            fs.link_files "$PKG_PATH/files-linux"
        fi

        if [ -d "$PKG_PATH/bin-linux" ]; then
            if [ ! -d "$HOME/bin" ]; then
                mkdir "$HOME/bin"
            fi
            fs.link_rfiles "$PKG_PATH/bin-linux" "$HOME/bin"
        fi
    fi

    if [ "$SYSTEM" == "mac" ]; then
        if [ -d "$PKG_PATH/files-mac" ]; then
            fs.link_files "$PKG_PATH/files-mac"
        fi

        if [ -d "$PKG_PATH/bin-mac" ]; then
            if [ ! -d "$HOME/bin" ]; then
                mkdir "$HOME/bin"
            fi
            fs.link_rfiles "$PKG_PATH/bin-mac" "$HOME/bin"
        fi
    fi
}

function common_install() {
    if [ -f "$PKG_PATH/install.sh" ]; then
        bash "$PKG_PATH/install.sh" "$ELLIPSIS_SRC" "$PKG_PATH" "$SYSTEM" "$MODE"
    fi

    if [ -f ".restart.lock" ]; then
        echo ""
        echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the installation.\e[0m"
        rm -rf .restart.lock
        exit 1
    fi

    echo "$PKG_PATH" >> "$HOME/ellipsis_installed.log"
}

function common_update() {
    if [ -f "$PKG_PATH/update.sh" ]; then
        bash "$PKG_PATH/update.sh" "$ELLIPSIS_SRC" "$PKG_PATH" "$SYSTEM" "$MODE"
    fi

    if [ -f ".restart.lock" ]; then
        echo ""
        echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the update.\e[0m"
        rm -rf .restart.lock
        exit 1
    fi
}

function common_update_and_link() {
    # Link new files
    common_link

    if [ -f "$PKG_PATH/update.sh" ]; then
        bash "$PKG_PATH/update.sh" "$ELLIPSIS_SRC" "$PKG_PATH" "$SYSTEM" "$MODE"
    fi

    if [ -f ".restart.lock" ]; then
        echo ""
        echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the update.\e[0m"
        rm -rf .restart.lock
        exit 1
    fi
}

function common_pull() {
    PACKAGE_HAS_UPDATES=0
    # Check for updates on git
    git remote update 2>&1 > /dev/null
    if git.is_behind; then
        # Unlink files
        hooks.unlink

        # Pull down the updates
        git.pull

        PACKAGE_HAS_UPDATES=1
    fi

    echo "$PKG_PATH" >> "$HOME/ellipsis_updated.log"
}

function common_uninstall() {
    echo "Run the uninstall script for $ELLIPSIS_PACKAGE? [y/n]"
    read -r var
    if [ "$var" == "y" ]; then
        if [ -f "$PKG_PATH/uninstall.sh" ]; then
            bash "$PKG_PATH/uninstall.sh" "$ELLIPSIS_SRC" "$PKG_PATH" "$SYSTEM" "$MODE"
        fi

        if [ -f ".restart.lock" ]; then
            echo ""
            echo -e "\e[33mPlease restart the computer and then re-run the ellipsis command to continue the uninstall.\e[0m"
            rm -rf .restart.lock
            exit 1
        fi
    fi

    echo "$PKG_PATH" >> "$HOME/ellipsis_uninstalled.log"
}

function common_hard_dependencies_check() {
    package=$1
    if [ -f "$PKG_PATH/hardDependencies.txt" ]; then
        mapfile -t hardDependencies < "$PKG_PATH/hardDependencies.txt"

        for program in ${hardDependencies[*]}; do
            if ! command -v "$program" &> /dev/null; then
                echo -e "\e[31mPackage \e[0m$package\e[31m has a hard dependency on \e[0m$program\e[31m which is missing. Please install \e[0m$program\e[31m before attempting this package installation again.\e[0m"
                printf "\e[31mPackage \e[0m%s\e[31m has a hard dependency on \e[0m%s\e[31m which is missing. Please install \e[0m%s\e[31m before attempting this package installation again.\e[0m\n" "$package" "$program" "$program" >> "$HOME/ellipsis_errors.log"
                MISSING_HARD_DEPENDENCIES=1
            fi
        done
    fi

    if [ "$MISSING_HARD_DEPENDENCIES" == "1" ]; then
        echo "$PKG_PATH" >> "$HOME/ellipsis_errored.log"
    fi
}

function common_soft_dependencies_check() {
    package=$1
    if [ -f "$PKG_PATH/softDependencies.txt" ]; then
        mapfile -t softDependencies < "$PKG_PATH/softDependencies.txt"

        for program in ${softDependencies[*]}; do
            if ! command -v "$program" &> /dev/null; then
                echo -e "\e[33mPackage \e[0m$package\e[33m has a soft dependency on \e[0m$program\e[33m which is missing. Some functionality may not work as expected.\e[0m"
                printf "\e[33mPackage \e[0m%s\e[33m has a soft dependency on \e[0m%s\e[33m which is missing. Some functionality may not work as expected.\e[0m\n" "$package" "$program" >> "$HOME/ellipsis_warnings.log"
                MISSING_SOFT_DEPENDENCIES=1
            fi
        done
    fi

    if [ "$MISSING_SOFT_DEPENDENCIES" == "1" ]; then
        echo "$PKG_PATH" >> "$HOME/ellipsis_warned.log"
    fi
}