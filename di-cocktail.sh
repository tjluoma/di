#!/bin/zsh -f
# Purpose: Download and install/update the latest version of Cocktail
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-13

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

HOMEPAGE="https://www.maintain.se/cocktail/"

DOWNLOAD_PAGE="https://www.maintain.se/cocktail/"

SUMMARY="Cocktail is a general purpose utility for macOS that lets you clean, repair and optimize your Mac. It is a powerful digital toolset that helps hundreds of thousands of Mac users around the world get the most out of their computers every day."

	# Don't share this one, different version for each version of macOS
INSTALL_TO="/Applications/Cocktail.app"

OS_VER=$(sw_vers -productVersion | cut -d. -f1,2)

if [ "$OS_VER" = "10.8" ]
then

	LATEST_VERSION='6.9'
	EXPECTED_SHASUM='309bac603a6ded301e9cc61b32bb522fc3a5208973cbd6c6f1a09d0e2c78d1e6'
	XML_FEED='https://www.maintain.se/downloads/sparkle/mountainlion/mountainlion.xml'
	URL='http://www.maintain.se/downloads/sparkle/mountainlion/Cocktail_6.9.zip'

elif [ "$OS_VER" = "10.9" ]
then

	LATEST_VERSION='7.9.1'
	EXPECTED_SHASUM='b8b5c37df3a2c44406f9fdf1295357d03b8fca6a9112b61401f0cca2b8e37033'
	XML_FEED='https://www.maintain.se/downloads/sparkle/mavericks/mavericks.xml'
	URL='http://www.maintain.se/downloads/sparkle/mavericks/Cocktail_7.9.1.zip'

elif [ "$OS_VER" = "10.10" ]
then

	LATEST_VERSION='8.9.2'
	EXPECTED_SHASUM='acc7d191313fa0eb4109ae56f62f73e7ed6685f7d7d438d5138b85d68e40edd8'
	XML_FEED='https://www.maintain.se/downloads/sparkle/yosemite/yosemite.xml'
	URL='https://www.maintain.se/downloads/sparkle/yosemite/Cocktail_8.9.2.zip'

elif [ "$OS_VER" = "10.11" ]
then

	LATEST_VERSION='9.7'
	EXPECTED_SHASUM='ca6b4a264ca60a08ff45761f82b0b6161cbe3412bd6cbeedd5dbecebc8d26712'
	XML_FEED='https://www.maintain.se/downloads/sparkle/elcapitan/elcapitan.xml'
	URL='https://www.maintain.se/downloads/sparkle/elcapitan/Cocktail_9.7.zip'

elif [ "$OS_VER" = "10.12" ]
then
	LATEST_VERSION='10.9.1'
	EXPECTED_SHASUM='c41bdcff4e0a1bdf3b0b1dfa11e12de71acf64010c7dccfd337ec2f42ca7bd4f'
	XML_FEED='https://www.maintain.se/downloads/sparkle/sierra/sierra.xml'
	URL='https://www.maintain.se/downloads/sparkle/sierra/Cocktail_10.9.1.zip'

elif [ "$OS_VER" = "10.13" ]
then

	XML_FEED='https://www.maintain.se/downloads/sparkle/highsierra/highsierra.xml'
	RELEASE_NOTES_URL='https://www.maintain.se/downloads/sparkle/highsierra/ReleaseNotes.html'

elif [ "$OS_VER" = "10.14" ]
then

	XML_FEED='https://www.maintain.se/downloads/sparkle/mojave/mojave.xml'
	RELEASE_NOTES_URL='https://www.maintain.se/downloads/sparkle/mojave/ReleaseNotes.html'

else

	echo "$NAME: Don't know what to do for $OS_VER."
	exit 1

fi

if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then

	INFO=($(curl -sSfL "${XML_FEED}" \
			| tr -s ' ' '\012' \
			| egrep 'sparkle:version|url=' \
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
		URL: $URL"
		exit 1
	fi

fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}-for-OS-${OS_VER}.zip"

if [[ "$RELEASE_NOTES_URL" != "" ]]
then
	if (( $+commands[lynx] ))
	then

		( curl -sfLS "${RELEASE_NOTES_URL}" \
			| sed '1,/^Release notes$/d; /^System Requirements$/,$d' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

	fi
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ "$EXPECTED_SHASUM" != "" ]]
then

	cd "$FILENAME:h"

	echo "$EXPECTED_SHASUM ?$FILENAME:t" > "$FILENAME:r.sha256.txt"

	echo -n "$NAME: Verifying shasum of '$FILENAME:t': "

	shasum -c "$FILENAME:r.sha256.txt"

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then
		echo "$NAME: Verification of '$FILENAME' was successful"

	else
		echo "$NAME: Verification of '$FILENAME' FAILED (\$EXIT = $EXIT)"

		exit 1
	fi

fi

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
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

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
#
#EOF
