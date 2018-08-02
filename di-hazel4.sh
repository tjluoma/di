#!/bin/zsh -f
# Purpose: Download and install the latest version of Hazel
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-23

## 2016-04-22 - changed from .dmg to .zip

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LOCAL_INSTALL="$HOME/Library/PreferencePanes/Hazel.prefPane"

SYSTEM_INSTALL='/Library/PreferencePanes/Hazel.prefPane'

if [ -e "$SYSTEM_INSTALL" -a -e "$LOCAL_INSTALL" ]
then
	echo "$NAME: Hazel is installed at BOTH $LOCAL_INSTALL and $SYSTEM_INSTALL. Please remove one."
	exit 1
elif [ -e "$SYSTEM_INSTALL" ]
then
	INSTALL_TO="$SYSTEM_INSTALL"
elif [ -e "$LOCAL_INSTALL" ]
then
	INSTALL_TO="$LOCAL_INSTALL"
else
	INSTALL_TO="$LOCAL_INSTALL"
fi

	# If there's no installed version, output 4.0.0 so the Sparkle feed will give us the proper download URL
	## DO NOT SET TO ZERO
INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '4.0.0'`

INFO=($(curl -sfL "https://www.noodlesoft.com/Products/Hazel/generate-appcast.php?version=$INSTALLED_VERSION" \
			| tr -s ' ' '\012' \
			| egrep '^(sparkle:version|url)=' \
			| head -2 \
			| awk -F'"' '/=/{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version >$LATEST_VERSION<"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/Hazel-$LATEST_VERSION.zip"

	# Server does not support continued downloads, so assume that this is incomplete and try again
[[ -f "$FILENAME" ]] && rm -f "$FILENAME"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

# If we get here we are ready to install

# Quit HazelHelper

pgrep -qx HazelHelper && pkill HazelHelper

if [ -e "$INSTALL_TO" ]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Hazel.$INSTALLED_VERSION.prefPane"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."

	exit 1
fi

if (is-growl-running-and-unpaused.sh)
then

	growlnotify  \
		--appIcon "HazelHelper" \
		--identifier "$NAME" \
		--message "Launching Hazel Helper" \
		--title "$NAME" 2>/dev/null
fi

echo "$NAME: Launching HazelHelper..."

open --background -a "$INSTALL_TO/Contents/MacOS/HazelHelper.app"

if [[ ! -e "$HOME/Library/Application Support/Hazel/license" ]]
then

	LICENSE="$HOME/Dropbox/dotfiles/licenses/hazel/Hazel-4.hazellicense"

	if [[ -e "$LICENSE" ]]
	then
		open "$LICENSE" || open -R "$LICENSE"
	else
		MSG="Hazel is unlicensed and no Hazel-4.hazellicense found at $LICENSE"

		echo "$NAME: $MSG"

		if (is-growl-running-and-unpaused.sh)
		then

			growlnotify \
				--appIcon "HazelHelper" \
				--identifier "$NAME" \
				--message "$MSG" \
				--title "$NAME" 2>/dev/null
		fi
	fi
fi

exit 0
#
#EOF
