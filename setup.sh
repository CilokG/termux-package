#!/bin/bash

pkg update -y > /dev/null 2>&1
pkg install termux-exec -y > /dev/null 2>&1

apt-get update -y > /dev/null 2>&1
apt-get --assume-yes upgrade > /dev/null 2>&1
apt-get --assume-yes install coreutils gnupg wget clang termux-api > /dev/null 2>&1

mkdir -p $PREFIX/etc/apt/sources.list.d
echo -e "deb https://nohajc.github.io termux extras" > $PREFIX/etc/apt/sources.list.d/termux-adb.list
wget -qP $PREFIX/etc/apt/trusted.gpg.d https://nohajc.github.io/nohajc.gpg
apt update -y  > /dev/null 2>&1
apt install termux-adb -y > /dev/null 2>&1
