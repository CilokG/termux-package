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

if [[ ! -f $PATH/fastboot ]] || [[ ! -f $PATH/adb ]]; then
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
	echo "2. Flash Recovery ROM"
	echo "3. Unlock Bootloader (Coming soon)"
	echo "4. Exit"
	
	echo ""
	read -p "Choose an option: " OPTION
	clear

	case "$OPTION" in
		1)
			echo "[GUIDE]"
			echo "   Type the command to go to your ROM folder"
			echo "   (example: cd /sdcard/ROM/)" 
			read -p "-> " CMD
			ROM_PATH_FOLDER=$(echo "$CMD" | awk '{print $2}')

			if [ ! -d "$ROM_PATH_FOLDER" ]; then
				echo "❌ Folder not found!"
				sleep 2
				continue
			fi

			cd "$ROM_PATH_FOLDER" || continue

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

			SCRIPT_FILES=($(find . -maxdepth 1 -type f -name "flash*.sh"))
			if [ ${#SCRIPT_FILES[@]} -eq 0 ]; then
				echo "❌ No flashable .sh files found!"
				sleep 2
				continue
			fi

			echo ""
			echo "[SELECTION]"
			echo "   Available flashable scripts:"

			FLASH_LIST=()
			INDEX=1
			
			for sh in "${!SCRIPT_FILES[@]}"; do
				FLASH_LIST+=("$sh")
				echo "   $INDEX) $(basename "${SCRIPT_FILES[$sh]}" .sh)"
				INDEX=$((INDEX + 1))
			done

			echo ""
			read -p "-> Select a script by number (1-${#SCRIPT_FILES[@]}): " CHOICE
			if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#SCRIPT_FILES[@]} )); then
				echo "❌ Invalid selection. Must be a number between 1 and ${#FLASH_LIST[@]}"
				sleep 2
				continue
			fi

			SELECTED_SCRIPT="$(basename "${SCRIPT_FILES[$((CHOICE- 1))]}")"
			echo "-> You selected: $SELECTED_SCRIPT"
			echo ""

			echo "[STARTED]"
			while true; do
				DEVICE_OUTPUT=$(fastboot devices 2>/dev/null)

				if echo "$DEVICE_OUTPUT" | grep -q "fastboot"; then
					echo -ne "\r   ✅ Device detected in fastboot mode!\033[K"; sleep 1.5
					echo -ne "\r\033[K"
					break
				else
					case "$dots" in
						"") dots="." ;;
						".") dots=".." ;;
						"..") dots="..." ;;
						"...") dots="" ;;
					esac
					echo -ne "\r   Waiting for device in fastboot mode$dots\033[K"
					sleep 0.5
				fi
			done

			echo "   ⚡ Starting flashing process..."
			echo ""
			bash "$SELECTED_SCRIPT"
			sleep 2
			;;
		
		2)
			echo "[GUIDE]"
			echo "   Type the command to go to your ROM folder"
			echo "   (example: cd /sdcard/ROM/)" 
			read -p "-> " CMD
			ROM_PATH_FILE=$(echo "$CMD" | awk '{print $2}')

			if [ ! -d "$ROM_PATH_FILE" ]; then
				echo "❌ Folder not found!"
				sleep 2
				continue
			fi
			
			ZIP_CHECK=($(find "$ROM_PATH_FILE" -maxdepth 1 -type f -name "*.zip"))
			if [ ${#ZIP_CHECK[@]} -eq 0 ]; then
				echo "❌ Not found .zip file in $ROM_PATH_FILE"
				sleep 2
				continue
			fi

			echo ""
			echo "[SELECTION]"
			echo "   Available flashable ROMs:"

			ROM_LIST=()
			INDEX=1
			shopt -s nullglob

			for zip in "${ZIP_CHECK[@]}"; do
				CHECK_ROM=$(unzip -l "$zip" | grep -E 'payload\.bin|payload_properties\.txt' 2>/dev/null)

				if [ -n "$CHECK_ROM" ]; then
					ROM_LIST+=("$zip")
					echo "   $INDEX) $(basename "$zip" .zip)"
					INDEX=$((INDEX + 1))
				fi
			done

			if [ ${#ROM_LIST[@]} -eq 0 ]; then
				echo "❌ No flashable ROMs found (missing payload files)."
				sleep 2
				continue
			fi

			echo ""
			read -p "-> Choose a ROM to flash (1-${#ROM_LIST[@]}): " CHOICE
			if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#ROM_LIST[@]} )); then
				echo "❌ Invalid selection. Must be a number between 1 and ${#ROM_LIST[@]}"
				sleep 2
				continue
			fi

			ROM_FILE="${ROM_LIST[$((CHOICE - 1))]}"
			echo "-> Selected ROM: $ROM_FILE"
			echo ""
			
			echo "[STARTED]"
			while true; do
				DEVICE_OUTPUT=$(adb devices 2>/dev/null)
				if echo "$DEVICE_OUTPUT" | grep -q "sideload"; then
					echo -ne "\r   ✅ Device detected in sideload mode!\033[K"; sleep 1.5
					echo -ne "\r\033[K"
					break
				else
					case "$dots" in
						"") dots="." ;;
						".") dots=".." ;;
						"..") dots="..." ;;
						"...") dots="" ;;
					esac
					echo -ne "\r   Waiting for device in sideload mode$dots\033[K"
					sleep 0.5
				fi
			done

			echo "   ⚡ Starting flashing process..."
			echo ""
			adb sideload "$ROM_FILE"
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