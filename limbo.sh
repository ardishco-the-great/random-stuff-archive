#!/bin/bash

# Winebo is a fork of Wineorc helper for Limbo

# Wineorc made by DarDarDar

# Winebo made by Seivok, 2023
# Some help from Ficello for Limbo (thanks!)

if [ $EUID == "0" ]; then
	echo "Please run this script as a non-root. "
	exit
fi

if [ "$1" == "--version" ]
then
	echo "Winebo v1.7 "
    echo ""
    echo "Wineorc v2.7 fork"
	echo "License: MIT (see https://github.com/DarDarDoor/Wineorc/blob/main/LICENSE) "
	exit
fi

if [ "$1" == "--help" ]
then
	echo "Winebo: The only script that matters (real) "
	echo "Usage: ./winebo.sh [OPTION]... "
	echo ""
	echo "Options: "
	echo "	uninstall: uninstalls a selected revival from a list of options "
	echo "	dxvk: installs dxvk, the directx to vulkan translation layer, to a wineprefix from a list of options. this can drastically improve performance in some revivals "
	echo "	--version: prints the version of Winebo that is being ran "
	echo "	--help: what you're reading right now, you idiot "
	echo ""
	echo "Example: "
	echo "	./winebo.sh dxvk "
	echo "Notes: "
    echo "	If you're getting HTTPs errors, then it might that you forgot to install extra dependencies for Wine. ¯\_(ツ)_/¯ "
	echo "	For more info, go on https://brinkervii.gitlab.io/grapejuice/docs/Installing-Wine.html "
	exit
fi

uninstall ()
{
	echo "Uninstalling $CURRENT now.. "
	sleep 3
	if [ $CURRENT == "Limbo16" ]
	then
		rm $HOME/.limbo16 -rf
		sudo rm /usr/share/applications/limbo16.desktop
	fi
	if [ $CURRENT == "Limbo18" ]
	then
		rm $HOME/.limbo18 -rf
		sudo rm /usr/share/applications/limbo18.desktop
	fi
	sudo update-desktop-database
	echo "Uninstall done. Run the script again if you'd like to reinstall. "
    exit
}

if [ "$1" == "uninstall" ] || [ "$2" == "uninstall" ]
then
	echo "Please select the revival you'd like to uninstall: "
	echo "1. Limbo (2016) "
	echo "2. Limbo (2018) "
	read UNINSTALLOPT 
	if [ $UNINSTALLOPT == "1" ]
	then
		CURRENT="Limbo16"
		uninstall
	fi
	if [ $UNINSTALLOPT == "2" ]
	then
		CURRENT="Limbo18"
		uninstall
	fi
fi
if [ "$1" == "dxvk" ] || [ "$2" == "dxvk" ]
then
	echo "Please select the wineprefix you'd like DXVK to install to: "
	echo "1. Limbo (2016) wineprefix "
	echo "1. Limbo (2018) wineprefix "
	read DXVKOPT
	mkdir $HOME/tmp
	cd $HOME/tmp
	wget https://github.com/doitsujin/dxvk/releases/download/v2.0/dxvk-2.0.tar.gz
	tar -xf dxvk-2.0.tar.gz
	cd dxvk-2.0
	if [ $DXVKOPT == "1" ]
	then
		WINEPREFIX=$HOME/.limbo16 ./setup_dxvk.sh install
	fi
    if [ $DXVKOPT == "2" ]
    then
        WINEPREFIX=$HOME/.limbo18 ./setup_dxvk.sh install
    fi
	cd $HOME
	rm tmp -rf
	echo "DXVK has been installed to selected wineprefix. "
	exit
fi

wineinstaller ()
{
    echo "Please accept any prompts it gives you and enter your password if necessary. "
    sleep 3
    DISTRO=`cat /etc/*release | grep DISTRIB_ID | cut -d '=' -f 2` # gets distro name
    if [ $DISTRO == "Ubuntu" ] || [ $DISTRO == "LinuxMint" ] || [ $DISTRO == "Pop" ]
    then 
        sudo dpkg --add-architecture i386 # wine installation prep
	sudo mkdir -pm755 /etc/apt/keyrings
	sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        VERSION=`lsb_release --release | cut -f2`
        if [ $VERSION == "22.04" ] || [ $VERSION == "21" ]
			        then 
				        wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
				        sudo mv winehq-jammy.sources /etc/apt/sources.list.d/
        fi
        if [ $VERSION == "21.10" ]
			        then 
         				wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/impish/winehq-impish.sources
				        sudo mv winehq-impish.sources /etc/apt/sources.list.d/
        fi
        if [ $VERSION == "20.04" ] || [ $VERSION == "20.3" ]
			        then 
				        wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources
				        sudo mv winehq-focal.sources /etc/apt/sources.list.d/
        fi			
        if [ $VERSION == "18.04" ] || [ $VERSION == "19.3" ] 
			        then 
				        wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/winehq-bionic.sources
				        sudo mv winehq-bionic.sources /etc/apt/sources.list.d/
        fi
        sudo apt update
        sudo apt install --install-recommends winehq-staging
    fi
    if [ $DISTRO == "Debian" ]
    then
        echo "If this fails, then a 32-bit multiarch does not exist. You should make one by following this guide: https://wiki.debian.org/Multiarch/HOWTO "
        sleep 3
        sudo apt-get install wine-development 
    fi
    if [ $DISTRO == "ManjaroLinux" ]
    then
        echo "If this fails, then the multilib repo is disabled in /etc/pacman.conf. The dependencies cannot be installed if this is disabled, so please enable it. "
        sleep 3
        sudo pacman -S wine-staging wine-mono expac # Arch Linux wine comes with a incredibly minimal package, so let's use expac to download everything it needs
	sudo pacman -S $(expac '%n %o' | grep ^wine)
    fi
    if [ $DISTRO == "Fedora" ]
    then
        sudo dnf install wine
    fi

    if [ $DISTRO == "Gentoo" ]
    then
        sudo emerge --ask virtual/wine-staging
    fi
    if [ ! -x /usr/bin/wine ]
    then
        echo "It seems the script couldn't install wine for you. Please install it manually. "
	exit
    fi
}

winecheck ()
{
    if [ ! -x /usr/bin/wine ]
    then
        read -p "Wine doesn't seem to be installed. This is required for the script to run. Would you like the script to install it for you? [y/n] " WINEINSTALLOPT
        if [ $WINEINSTALLOPT = "y" ]
        then
            wineinstaller
        else
            echo "OK, the script *won't* install wine for you. Please kill the script and install it manually. If you're sure it's installed, then don't kill the script. "
            sleep 3
        fi
    else
        echo "wine is installed, skipping check.. "
    fi
}

othercheck ()
{
	if [ ! -x /usr/bin/wget ]
	then
		echo "wget seems to not be installed. Please kill the script then install wget via your package manager. "
		echo "If you're sure it's installed, then don't kill the script. "
		sleep 3
	else
		echo "wget is installed, skipping check.. "
	fi
	if [ $CURRENT == "Limbo" ]
	then	
		if [ ! -x /usr/bin/curl ]
		then
			echo "curl seems to not be installed. Please kill the script then install curl via your package manager. "
			echo "If you're sure it's installed, then don't kill the script. "
			sleep 3
		else
			echo "curl is installed, skipping check.. "
		fi
	fi
}

uri ()
{
	if [ $CURRENT == "Limbo16" ]
	then
		touch limbo16.desktop
		echo "[Desktop Entry]" >> limbo16.desktop
		echo "Name=Limbo16" >> limbo16.desktop
		echo "Comment=https://roblox.cat" >> limbo16.desktop
		echo "Type=Application" >> limbo16.desktop
		if [ $DIRECTORY == "PROGRAMFILES" ]
		then
		echo "Exec=env WINEPREFIX=$HOME/.limbo16 wine $HOME/.limbo16/drive_c/'Program Files (x86)'/LimRev/Versions/version-934c86ec4aa148f0/LimRevPlayerLauncher.exe %u" >> limbo16.desktop
		fi
		if [ $DIRECTORY == "APPDATA" ]
		then
        echo "Exec=env WINEPREFIX=$HOME/.limbo18 wine $HOME/.limbo18/drive_c/users/$USER/AppData/Local/LimRev/Versions/version-934c86ec4aa148f0/LimRevPlayerLauncher.exe %u" >> limbo16.desktop
		fi
		echo "MimeType=x-scheme-handler/limb16-player" >> limbo16.desktop
	fi
	if [ $CURRENT == "Limbo18" ]
	then
		touch limbo18.desktop
		echo "[Desktop Entry]" >> limbo18.desktop
		echo "Name=Limbo18" >> limbo18.desktop
		echo "Comment=https://roblox.cat" >> limbo18.desktop
		echo "Type=Application" >> limbo18.desktop
		if [ $DIRECTORY == "PROGRAMFILES" ]
		then
		echo "Exec=env WINEPREFIX=$HOME/.limbo18 wine $HOME/.limbo18/drive_c/'Program Files (x86)'/LimRev/Versions/version-d30b938ea76a153e/RobloxPlayerLauncher.exe %u" >> limbo18.desktop
		fi
		if [ $DIRECTORY == "APPDATA" ]
		then
        echo "Exec=env WINEPREFIX=$HOME/.limbo18 wine $HOME/.limbo18/drive_c/users/$USER/AppData/Local/LimRev/Versions/version-d30b938ea76a153e/RobloxPlayerLauncher.exe %u" >> limbo18.desktop
		fi
		echo "MimeType=x-scheme-handler/limb18-player" >> limbo18.desktop
	fi
	sudo mv *.desktop /usr/share/applications
	sudo update-desktop-database
}

limbo16 ()
{
	winecheck
	othercheck
	echo "$CURRENT is now being installed, please wait as this may take some time. "
	sleep 3
	mkdir $HOME/.limbo16
	WINEPREFIX=$HOME/.limbo16 winecfg -v win10
	cd $HOME/.limbo16/drive_c/users/$USER/AppData/Local # we're doing this cos it installs the client in the same folder as where the installer is ran
	wget https://cdn.discordapp.com/attachments/979100227300646922/1114719578719801445/LimRevPlayerLauncher.exe
	echo "Don't panic if this looks stuck. Give it a few minutes, if it doesn't work then stop the script, uninstall Limbo16 using the script, then try running the script again. Once the installer finishes, press ctrl+c to close if it looks stuck."
	sleep 3
	WINEPREFIX=$HOME/.limbo16 wine LimRevPlayerLauncher.exe
	uri
}
limbo18 ()
{
	winecheck
	othercheck
	echo "$CURRENT is now being installed, please wait as this may take some time. "
	sleep 3
	mkdir $HOME/.limbo18
	WINEPREFIX=$HOME/.limbo18 winecfg -v win10
	cd $HOME/.limbo18/drive_c/users/$USER/AppData/Local # we're doing this cos it installs the client in the same folder as where the installer is ran
	wget https://cdn.discordapp.com/attachments/979100227300646922/1113761036139507794/RobloxPlayerLauncher.exe
	echo "Don't panic if this looks stuck. Give it a few minutes, if it doesn't work then stop the script, uninstall Limbo18 using the script, then try running the script again. Once the installer finishes, press ctrl+c to close if it looks stuck."
	sleep 3
	WINEPREFIX=$HOME/.limbo18 wine RobloxPlayerLauncher.exe
	uri
}

echo "
 __          ___            _           
 \ \        / (_)          | |           TM  
  \ \  /\  / / _ _ __   ___| |__   ___  
   \ \/  \/ / | | '_ \ / _ \ '_ \ / _ \ 
    \  /\  /  | | | | |  __/ |_) | (_) |
     \/  \/   |_|_| |_|\___|_.__/ \___/

"

echo "Welcome to Winebo, please select an revival to install. (see --help for other options) "
echo "1. Limbo (2016) "
echo "2. Limbo (2018) "
echo " "
read OPT
echo "Select the directory (this is for troubleshooting purposes, please select the 2nd option if launching doesn't work.) "
echo "1. Local AppData (Default) "
echo "2. Program Files x86 "
echo " "
read DIR

if [ $DIR == "1" ] # directory stuff
then
	DIRECTORY="APPDATA"
fi
if [ $DIR == "2" ]
then
	DIRECTORY="PROGRAMFILES"
fi

if [ $OPT == "1" ] # revival stuff
then
	CURRENT="Limbo16"
	limbo16
fi
if [ $OPT == "2" ]
then
	CURRENT="Limbo18"
	limbo18
fi

wineserver -k
cd $HOME
rm tmp -rf
echo "$CURRENT should now be installed! Try playing a game and it should work! "
exit
