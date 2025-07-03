#!/bin/bash

case $(dpkg --print-architecture) in
	aarch64|arm) ;;
	*) echo -e "\nThis tool does not support this architecture\n"; exit 1 ;;
esac

if dpkg -l | grep -q android-tools; then
	pkg uninstall -y android-tools > /dev/null 2>&1
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

TOTAL=13
COUNT=0
BAR_LENGTH=20

SHOW_PROGRESS() {
  percent=$((COUNT * 100 / TOTAL))
  filled=$((COUNT * BAR_LENGTH / TOTAL))
  empty=$((BAR_LENGTH - filled))

  bar=$(printf "%0.s█" $(seq 1 $filled))
  bar+=$(printf "%0.s░" $(seq 1 $empty))

  echo -ne "[${bar}] ($COUNT/$TOTAL) ${percent}%\r"
}

NEXT_STEP() {
  COUNT=$((COUNT + 1))
  SHOW_PROGRESS
  sleep 0.2
}

apt-get update > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes upgrade > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes install coreutils > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes install gnupg > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes install wget > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes install clang > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes install termux-api > /dev/null 2>&1 && NEXT_STEP

mkdir -p $PREFIX/etc/apt/sources.list.d && NEXT_STEP
echo "deb https://nohajc.github.io termux extras" > $PREFIX/etc/apt/sources.list.d/termux-adb.list && NEXT_STEP
wget -qP $PREFIX/etc/apt/trusted.gpg.d https://nohajc.github.io/nohajc.gpg && NEXT_STEP
apt-get update > /dev/null 2>&1 && NEXT_STEP
apt-get --assume-yes install termux-adb > /dev/null 2>&1 && NEXT_STEP

curl -sSL https://raw.githubusercontent.com/CilokG/termux-package/master/main.c | clang -x c -o flasher - && NEXT_STEP
ln -sf termux-fastboot fastboot && ln -sf termux-adb adb

echo ""
echo -e "\n✅ Required package installed\n   Usage Command: \033[1;32mflasher\033[0m\n"
