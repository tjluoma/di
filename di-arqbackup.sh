#!/bin/zsh -f
# Purpose: Download and install the latest version of Arq
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-02-29

NAME="$0:t:r"

INSTALL_TO='/Applications/Arq.app'

HOMEPAGE="https://www.arqbackup.com"

DOWNLOAD_PAGE="https://www.arqbackup.com/download/Arq.dmg"

SUMMARY="Arq automatically backs up all your Macs and Windows PCs. Your files are stored securely, readable only by you."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED="https://www.arqbackup.com/download/arq5.xml"

	# no other version information in feed
INFO=($(curl -sfL "$XML_FEED" \
| tr -s ' ' '\012' \
| egrep 'sparkle:version=|url=' \
| fgrep -v 'arq_updater_url' \
| head -2 \
| sort \
| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '5.0.0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload -U is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL='https://www.arqbackup.com/download/arq5_release_notes.html'

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION:\n" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<h1>/d; /<h1>/,$d' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0


UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"


exit 0



###




## 2018-07-20 - the new URL gives us a usable .zip instead of a .dmg
## Silently mount the DMG
# MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
# 		| fgrep -A 1 '<key>mount-point</key>' \
# 		| tail -1 \
# 		| sed 's#</string>.*##g ; s#.*<string>##g')
#
# if [[ "$MNTPNT" == "" ]]
# then
# 	echo "$NAME: MNTPNT is empty"
# 	exit 1
# fi
#
# echo "$NAME: Installing \"$MNTPNT/Arq.app\" to \"$INSTALL_TO\":"
#
# ditto --noqtn -v "$MNTPNT/Arq.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation/update of $INSTALL_TO successful"

else
	echo "$NAME: 'ditto --noqtn' failed (\$EXIT = $EXIT)"

	exit 1
fi

# diskutil eject "$MNTPNT"

exit 0

####################################################################################################
##
## 2018-07-10 - the script below was from when we were using the URL from the Sparkle
## 					feed, which gave us a .zip file instead of a DMG.
##					I am saving it in case the Sparkle feed resumes working in the future.


FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

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
fi



exit 0

## These are old:
# XML_FEED='https://www.arqbackup.com/download/arq4.xml'

#EOF
