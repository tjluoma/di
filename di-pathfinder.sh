#!/bin/zsh -f
# Purpose: Download and install the latest version of PathFinder 7 or 8 from <https://cocoatech.com/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-21

NAME="$0:t:r"

INSTALL_TO='/Applications/Path Finder.app'

HOMEPAGE="https://cocoatech.com/"

DOWNLOAD_PAGE="https://get.cocoatech.com/PF8.zip"

SUMMARY="File manager for macOS."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

function use_v7 {

	URL="https://get.cocoatech.com/PF7.zip"

		## I determined LATEST_VERSION & LATEST_BUILD by downloading 'https://get.cocoatech.com/PF7.zip'
		# on 2018-07-17. I do not think PathFinder 7 will be updated anymore,
		# so this is likely to be the last version.
	LATEST_VERSION="7.6.2"
	LATEST_BUILD="1729"
	ASTERISK='(Note that version 8 is also available.)'
	USE_VERSION='7'

}

function use_v8 {

	USE_VERSION='8'
	XML_FEED="http://sparkle.cocoatech.com/PF8.xml"

	INFO=($(curl -sfL $XML_FEED \
			| egrep '<(build|version|url)>' \
			| sort \
			| awk -F'>|<' '//{print $3}'))

	LATEST_BUILD="$INFO[1]"
	URL="$INFO[2]"
	LATEST_VERSION="$INFO[3]"

}

if [[ -e "$INSTALL_TO" ]]
then
		# if v7 is installed, check that. Otherwise, use v8
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "7" ]]
	then
		use_v7
	else
		use_v8
	fi
else
	if [ "$1" = "--use7" -o "$1" = "-7" ]
	then
		use_v7
	else
		use_v8
	fi
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/PathFinder-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if [[ "$USE_VERSION" == "8" ]]
then
	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL="$XML_FEED"

		( curl -sfLS "$RELEASE_NOTES_URL" \
			| sed '1,/<\!\[CDATA\[/d; /\]\]>/,$d' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
			| sed '/./,/^$/!d' \
			| sed 's#^ *##g' ;
			echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"
	fi
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
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	local TRASH="$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	COUNT='0'

	while [ -e "$TRASH" ]
	do
		((COUNT++))
		TRASH="$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.($COUNT).app"
	done

	mv -vf "$INSTALL_TO" "$TRASH"

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

#EOF
