clear
echo -e "\033[1;32m"

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

dots=""
echo -ne "📦 Installing required package"
(curl -sS https://raw.githubusercontent.com/CilokG/termux-package/master/setup.sh | bash) & INSTALL_PID=$!

while kill -0 $INSTALL_PID 2>/dev/null; do
	case "$dots" in
		"") dots="." ;;
		".") dots=".." ;;
		"..") dots="..." ;;
		"...") dots="" ;;
	esac

	echo -ne "\r📦 Installing required package$dots\033[K"
	sleep 0.4 > /dev/null 2>&1
done

wait $INSTALL_PID
curl -sSL https://raw.githubusercontent.com/CilokG/termux-package/master/main.c | clang -x c -o $PREFIX/bin/flasher -
echo -ne "\r✅ Required package installed!\033[K\n"

mv $PREFIX/bin/termux-fastboot $PREFIX/bin/fastboot > /dev/null 2>&1
mv $PREFIX/bin/termux-adb $PREFIX/bin/adb > /dev/null 2>&1
sleep 1.25 
