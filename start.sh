clear
echo -e "\033[1;32m"

#Thanks MiTools for some script
#Thanks RohitVerma882 for some script

CHECK=$(dpkg -l | grep android-tools)
ANDROID_TOOLS=$(echo "$CHECK" | awk '{print $2}')

if [ "$ANDROID_TOOLS" ]; then
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

arch=$(dpkg --print-architecture)

if [[ "$arch" != "aarch64" && "$arch" != "arm" ]]; then
	echo "This tool does not support architecture $arch"
	exit 1
fi

if [[ ! -d $PATH/fastboot ]] || [[ ! -d $PATH/adb ]]; then
	dots=""
	echo -ne "📦 Installing required package"
	(pkg update && pkg install termux-exec && pkg install git -y) > /dev/null 2>&1 & INSTALL_PID=$!

	while kill -0 $INSTALL_PID 2>/dev/null; do
		case "$dots" in
			"") dots="." ;;
			".") dots=".." ;;
			"..") dots="..." ;;
			"...") dots="" ;;
		esac

		echo -ne "\r📦 Installing required package$dots\033[K"
		sleep 0.4
	done

	wait $INSTALL_PID
	echo -ne "\r✅ Required package installed!\033[K\n"

	dots=""
	echo -ne "📥 Cloning git repository"
	(git clone https://github.com/CilokG/termux-package.git > /dev/null 2>&1) & CLONE_PID=$!

	while kill -0 $CLONE_PID 2>/dev/null; do
		case "$dots" in
			"") dots="." ;;
			".") dots=".." ;;
			"..") dots="..." ;;
			"...") dots="" ;;
		esac

		echo -ne "\r📥 Cloning git repository$dots\033[K"
		sleep 0.4
	done

	wait $CLONE_PID
	echo -ne "\r✅ Repository git cloned!\033[K\n"

	dots=""
	echo -ne "⚙️  Running git setup.sh"
	(bash termux-package/setup.sh > /dev/null 2>&1) & SETUP_PID=$!

	while kill -0 $SETUP_PID 2>/dev/null; do
		case "$dots" in
			"") dots="." ;;
			".") dots=".." ;;
			"..") dots="..." ;;
			"...") dots="" ;;
		esac

		echo -ne "\r⚙️  Running git setup$dots\033[K"
		sleep 0.4
	done

	wait $SETUP_PID
	echo -ne "\r✅ Setup git complete!\033[K\n"

	sleep 2
	rm -rf termux-package
fi 

while true; do
	clear
	echo -e "\033[1;32m"
	
	echo "======== Main Menu ========"
	echo ""
	echo "1. Flash Fastboot ROM"
	echo "2. Flash Recovery ROM (Coming soon)"
	echo "3. Unlock Bootloader (Coming soon)"
	echo "4. Exit"
	
	echo ""
	read -p "Choose an option: " OPTION
	clear

	case "$OPTION" in
		1)
			echo "[GUIDE]"
			echo "   Type the command to go to your ROM folder"
			echo "   (example: cd /sdcard/ROM)" 
			read -p "-> " CMD
			ROM_PATH=$(echo "$CMD" | awk '{print $2}')

			if [ ! -d "$ROM_PATH" ]; then
				echo "❌ Folder not found!"
				sleep 2
				continue
			fi

			cd "$ROM_PATH" || exit

			if [ ! -d "images" ]; then
				echo "❌ 'images' folder not found!"
				sleep 2
				continue
			fi

			FILES=$(find "images" -maxdepth 1 -type f \( -name "*.img" -o -name "*.bin" \))
			if [ -z "$FILES" ]; then
				echo "❌ No such .img  and .bin files in 'images' folder!"
				sleep 2
				continue
			fi

			FLASH_FILES=($(find . -maxdepth 1 -type f -name "*.sh"))
			if [ ${#FLASH_FILES[@]} -eq 0 ]; then
				echo "❌ No flashable .sh files found!"
				sleep 2
				continue
			fi

			echo ""
			echo "[SELECTION]"
			echo "   Available flash scripts:"
			for i in "${!FLASH_FILES[@]}"; do
				echo "   $((i+1)). $(basename "${FLASH_FILES[$i]}" .sh)"
			done

			echo ""
			read -p "-> Select a script by number: " SCRIPT_INDEX
			if ! [[ "$SCRIPT_INDEX" =~ ^[0-9]+$ ]] || (( SCRIPT_INDEX < 1 || SCRIPT_INDEX > ${#FLASH_FILES[@]} )); then
				echo "❌ Invalid selection!"
				sleep 2
				continue
			fi

			SELECTED_SCRIPT="${FLASH_FILES[$((SCRIPT_INDEX-1))]}"
			echo "-> You selected: $SELECTED_SCRIPT"
			echo ""

			while true; do
				DEVICE_OUTPUT=$(fastboot devices)
			
				if echo "$DEVICE_OUTPUT" | grep -q "fastboot"; then
					echo -ne "\r✅Device detected!\033[K"; sleep 1.5
					echo -ne "\r\033[K"
					break
				else
					case "$dots" in
						"") dots="." ;;
						".") dots=".." ;;
						"..") dots="..." ;;
						"...") dots="" ;;
					esac
					
					echo -ne "\rWaiting for device in fastboot mode$dots\033[K"
					sleep 0.5
				fi
			done

			clear
			echo "⚡ Starting flashing process..."
			echo ""
			
			bash "$SELECTED_SCRIPT"
			sleep 2
			;;

		4)
			echo "Exiting..."
			exit 0
			;;

		*)
			echo "❌ Invalid option, please try again."
			sleep 1
			;;
	esac
done
