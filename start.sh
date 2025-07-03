#!/bin/bash

case $(dpkg --print-architecture) in
    aarch64|arm) ;;
    *) echo -e "\nThis tool does not support this architecture\n"; exit 1 ;;
esac

if dpkg -l | grep -q android-tools; then
    pkg uninstall -y android-tools > /dev/null 2>&1 || { exit 1; }
fi

if [ ! -d "$HOME/storage" ]; then
    echo -e "\nGrant permission first: termux-setup-storage\n"
    exit 1
fi

if [ ! -d "/data/data/com.termux.api" ]; then
    echo -e "\nTermux API app is not installed\nPlease install it first\n"
    exit 1
fi

cd "$PREFIX/bin/"
echo -e "\n📦 Installing required package\n   This may take a while\n"

TOTAL_STEPS=13
CURRENT_STEP=0
BAR_LENGTH=20

SHOW_PROGRESS() {
    percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    filled=$((CURRENT_STEP * BAR_LENGTH / TOTAL_STEPS))
    empty=$((BAR_LENGTH - filled))

    bar=$(printf "%0.s█" $(seq 1 $filled))
    bar+=$(printf "%0.s░" $(seq 1 $empty))
    echo -ne "[${bar}] ($CURRENT_STEP/$TOTAL_STEPS) ${percent}%\r"
}

NEXT_STEP() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    SHOW_PROGRESS
    sleep 0.2
}

COMMANDS=(
    "apt-get update > /dev/null 2>&1"
    "apt-get --assume-yes upgrade > /dev/null 2>&1"
    "apt-get --assume-yes install coreutils > /dev/null 2>&1"
    "apt-get --assume-yes install gnupg > /dev/null 2>&1"
    "apt-get --assume-yes install wget > /dev/null 2>&1"
    "apt-get --assume-yes install clang > /dev/null 2>&1"
    "apt-get --assume-yes install termux-api > /dev/null 2>&1"
    "mkdir -p $PREFIX/etc/apt/sources.list.d"
    "echo \"deb https://nohajc.github.io termux extras\" > $PREFIX/etc/apt/sources.list.d/termux-adb.list"
    "wget -qP $PREFIX/etc/apt/trusted.gpg.d https://nohajc.github.io/nohajc.gpg"
    "apt-get update > /dev/null 2>&1"
    "apt-get --assume-yes install termux-adb > /dev/null 2>&1"
    "curl -sSL https://raw.githubusercontent.com/CilokG/termux-package/master/main.c | clang -x c -o flasher -"
)

for CMD in "${COMMANDS[@]}"; do
	eval "$CMD" && NEXT_STEP || { exit 1; }
done

ln -sf termux-fastboot fastboot && ln -sf termux-adb adb
echo -e "\n\n✅ Required package installed\n   Usage Command: \033[1;32mflasher\033[0m\n"
