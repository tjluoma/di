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
	LATEST_VERSION='10.8'
	EXPECTED_SHASUM='54fb6665cd43f4fb1a536e475fe71d6f1ca12ff547948a35e6625f2fb7997578'
	XML_FEED='https://www.maintain.se/downloads/sparkle/sierra/sierra.xml'
	URL='https://www.maintain.se/downloads/sparkle/sierra/Cocktail_10.9.1.zip'

elif [ "$OS_VER" = "10.13" ]
then

	#LATEST_VERSION='11.6.2'
	#EXPECTED_SHASUM='3ebb51b302a16dabefe54a434b9d114d64627e30c6681b8c9ac8d8f6185b8f6c'
	XML_FEED='https://www.maintain.se/downloads/sparkle/highsierra/highsierra.xml'
	RELEASE_NOTES_URL='https://www.maintain.se/downloads/sparkle/highsierra/ReleaseNotes.html'

# sparkle:version="11.6.3"

elif [ "$OS_VER" = "10.14" ]
then

	#LATEST_VERSION='11.6.2'
	#EXPECTED_SHASUM='3ebb51b302a16dabefe54a434b9d114d64627e30c6681b8c9ac8d8f6185b8f6c'
	XML_FEED='https://www.maintain.se/downloads/sparkle/mojave/mojave.xml'
	RELEASE_NOTES_URL='https://www.maintain.se/downloads/sparkle/mojave/ReleaseNotes.html'
else

	echo "$NAME: Don't know what to do for $OS_VER."
	exit 1

fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	( curl -sfLS "${RELEASE_NOTES_URL}" \
		| sed '1,/^Release notes$/d; /^System Requirements$/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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
#
#EOF
