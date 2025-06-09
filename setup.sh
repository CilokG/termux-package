#!/bin/bash
CURRENT=$(dirname "$(realpath "$0")"); cd "$CURRENT"
cp -rf * $PREFIX

chmod +x $PATH/fastboot
chmod +x $PATH/adb
chmod +x $PATH/zstd

apt-get update -y > /dev/null 2>&1
apt-get --assume-yes upgrade > /dev/null 2>&1
apt-get --assume-yes install coreutils gnupg wget termux-api openjdk-17 vim ncurses perl which > /dev/null 2>&1
