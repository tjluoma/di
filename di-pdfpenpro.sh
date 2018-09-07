#!/bin/zsh -f
# Purpose: Download and install PDFPenPro version 8, 9, or 10 from <https://smilesoftware.com/pdfpenpro/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-21

NAME="$0:t:r"

INSTALL_TO='/Applications/PDFpenPro.app'

HOMEPAGE="https://smilesoftware.com/PDFpenPro"

DOWNLOAD_PAGE="https://dl.smilesoftware.com/com.smileonmymac.PDFpenPro/PDFpenPro.dmg"

SUMMARY="Powerful PDF Editing On Your Mac. Add signatures, text, and images. Make changes and correct typos. OCR scanned docs. Fill out and create forms. Export to Microsoft Word, Excel, PowerPoint."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

function use_v8 {

	USE_VERSION='8'

	LATEST_VERSION="8.3.4"

	LATEST_BUILD="834.1"

	URL="https://dl.smilesoftware.com/com.smileonmymac.PDFpenPro/834.1/1491270914/PDFpenPro-834.1.zip"

	ASTERISK='(Note that version 10 is also available.)'

}

function use_v9 {

	USE_VERSION='9'

	LATEST_VERSION="9.2.3"

	LATEST_BUILD="923.0"

	URL="https://dl.smilesoftware.com/com.smileonmymac.PDFpenPro/923.0/1510025685/PDFpenPro-923.0.zip"

	ASTERISK='(Note that version 10 is also available.)'

}

function use_v10 {

	USE_VERSION='10'

	ITUNES_URL='itunes.apple.com/us/app/pdfpenpro-10/id1359910358'

		# 2018-07-17 - found alternate URL which seems to have identical info:
		# https://updates.devmate.com/com.smileonmymac.PDFpenPro.xml

	XML_FEED='https://updates.smilesoftware.com/com.smileonmymac.PDFpenPro.xml'

	INFO=($(curl -sfL "$XML_FEED" \
			| tr -s ' ' '\012' \
			| egrep '^(sparkle:version|sparkle:shortVersionString|url=)' \
			| head -3 \
			| sort \
			| awk -F'"' '/^/{print $2}'))

	LATEST_VERSION="$INFO[1]"

	LATEST_BUILD="$INFO[2]"

	URL="$INFO[3]"

		# If any of these are blank, we should not continue
	if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
	then
		echo "$NAME: Error: bad data received:
		INFO: $INFO
		LATEST_VERSION: $LATEST_VERSION
		LATEST_BUILD: $LATEST_BUILD
		URL: $URL
		"

		exit 1
	fi
}

if [[ -e "$INSTALL_TO" ]]
then
		# if v8 or 9 are installed, check that. Otherwise, use v10
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if   [[ "$MAJOR_VERSION" == "8" ]]
	then
		use_v8
	elif [[ "$MAJOR_VERSION" == "9" ]]
	then
		use_v9
	else
		use_v10
	fi
else
	if   [ "$1" = "--use8" -o "$1" = "-8" ]
	then
		use_v8
	elif [ "$1" = "--use9" -o "$1" = "-9" ]
	then
		use_v9
	else
		use_v10
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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."

		if [[ "$ITUNES_URL" != "" ]]
		then
			echo "	See <https://$ITUNES_URL?mt=12> or"
			echo "	<macappstore://$ITUNES_URL>"
		fi

		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep '<sparkle:releaseNotesLink>' \
	| head -1 \
	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if [[ "$USE_VERSION" == "10" ]]
then

	if (( $+commands[lynx] ))
	then

		( echo -n "$NAME: Release Notes for " ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| fgrep -v 'please note: PDFpenPro 10 is a paid upgrade' \
		| sed '1,/<div class="dm-rn-head-title-fixed">/d' \
		| sed '/<\/ul><\/li>/,$d' \
		| lynx -dump -nomargins -width='90' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

	fi
fi

## Download it

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

#
#EOF
