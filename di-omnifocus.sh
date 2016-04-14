#!/bin/zsh -f
# Download and install the latest OmniFocus
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-26

NAME="$0:t:r"

LAUNCH='no'

## Note: Downloads are available in tbz2 and dmg but dmg has EULA so I use tbz2

INFO=($(curl -sfL "http://update.omnigroup.com/appcast/com.omnigroup.OmniFocus2/" 2>&1 \
| sed 's#<#\
<#g' \
| tr -s ' ' '\012' \
| egrep '<omniappcast:marketingVersion>|url=.*\.tbz2' \
| head -2 \
| tr -s '>|"' ' ' \
| awk '{print $NF}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

INSTALL_TO='/Applications/OmniFocus.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info"  CFBundleShortVersionString 2>/dev/null || echo '0'`

 if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
 then
 	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
 	exit 0
 fi

autoload is-at-least

 is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"
 
 if [ "$?" = "0" ]
 then
 	echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
 	exit 0
 fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/OmniFocus-$LATEST_VERSION.tbz2"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

	# Quit app if running
pgrep -qx 'OmniFocus' && LAUNCH='yes' && osascript -e 'tell application "OmniFocus" to quit'

if [ -e "$INSTALL_TO" ]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/OmniFocus.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

tar -x -C "$INSTALL_TO:h" -f "$FILENAME"

[[ "$LAUNCH" == "yes" ]] && open --background -a "$INSTALL_TO"

exit 0

#EOF
