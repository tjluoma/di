#!/bin/zsh -f
# Purpose: Download and install the latest version of Fine Reader Pro
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-09

NAME="$0:t:r"

INSTALL_TO='/Applications/FineReader.app'

HOMEPAGE="https://www.abbyy.com/en-us/finereader/pro-for-mac/"

DOWNLOAD_PAGE="https://www.abbyy.com/en-us/lp/finereader-mac-download-free-trial/"

SUMMARY="Easily transform paper documents, PDFs and digital photos of text into editable and searchable files. No more manual retyping or reformatting. Instead you can search, share, archive, and copy information from documents for reuse and quotation — saving you time, effort and hassles."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

if [ -e "$INSTALL_TO" ]
then

		# TurnsOut™, the DYNAMIC_URL doesn't technically need a valid serial number to work,
		# but we'll use one if we find it, otherwise we'll use a fake one instead.
	FINE_READER_PRO_SERIAL=$(defaults read com.abbyy.FineReaderPro com.abbyy.fine-reader.serial-number 2>/dev/null || echo 'FSAR00000000000000000000')

	BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion`

	MAJOR_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d . -f 1,2`

	REVISION_NUMBER=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d . -f 3`

	PART_NUMBER=`defaults read "$INSTALL_TO/Contents/Info" PartNumber`

	# THIS IS NEW as of 2018-07-10
DYNAMIC_URL="https://www.abbyy.com/en-us/checkforupdates/?Product=FRProMac&Distributive=Retail&Serial=${FINE_READER_PRO_SERIAL}&Language=en&PartNumber=1215%2f10&Target=CheckUpdate&Version=${MAJOR_VERSION}&Revision=${REVISION_NUMBER}&Build=${BUILD}"

		##
		## WARNING: 2018-07-10 - this is web scraping, so very prone to breaking
		##
	CURRENT_PART_NUMBER=`curl -sfL "$DYNAMIC_URL" \
	| fgrep 'Update Part Number:' \
	| sed 's#<br/>##g' \
	| tr -dc '[0-9]/'`

	if [[ "$CURRENT_PART_NUMBER" == "$PART_NUMBER" ]]
	then
		echo "$NAME: Up-To-Date ($PART_NUMBER)"
		## echo "$DYNAMIC_URL" # can be useful for debugging
		exit 0
	elif [[ "$CURRENT_PART_NUMBER" == "" ]]
	then
		echo "$NAME: \$CURRENT_PART_NUMBER is empty. Web scraping has apparently failed."
		exit 1
	fi

fi

## If we get here, either an update is available or the app isn't installed at all

URL="http://fr7.abbyy.com/mac/fr/ABBYY_FineReader_Pro_ESD.dmg"

if [[ "$CURRENT_PART_NUMBER" != "" ]]
then

	CURRENT_PART_NUMBER_SAFE=`echo "$CURRENT_PART_NUMBER" | tr '/' '.'`

	FILENAME="$HOME/Downloads/FineReaderPro-$CURRENT_PART_NUMBER_SAFE.dmg"

	RENAME_AFTER_INSTALL='no'

else
	zmodload zsh/datetime

	DATE=`strftime "%Y-%m-%d" "$EPOCHSECONDS"`

	FILENAME="$HOME/Downloads/FineReaderPro-${DATE}.dmg"

	RENAME_AFTER_INSTALL='yes'
fi

if [[ "$DYNAMIC_URL" != "" ]]
then
	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL="$DYNAMIC_URL"

		(curl -sfLS "$RELEASE_NOTES_URL" \
			| sed '1,/<article class="release-note">/d; /<\/article>/,$d' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		 echo "\nSource: <$RELEASE_NOTES_URL>") | tee -a "$FILENAME:r.txt"

	fi
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

if [[ "$DYNAMIC_URL" != "" ]]
then
	echo "	See <$DYNAMIC_URL> for release notes."
fi

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: "

diskutil eject "$MNTPNT"

BUILD=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion)

MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d . -f 1,2)

REVISION_NUMBER=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d . -f 3)

	# note that this is what shows up on the website, so it's first, but we have to replace '/'
	# so I chose a '.'
PART_NUMBER=$(defaults read "$INSTALL_TO/Contents/Info" PartNumber | tr '/' '.')

	# rename the download the have a lot of important bits of information in the name
mv -vn "$FILENAME" "$HOME/Downloads/FineReaderPro-${PART_NUMBER}-${MAJOR_VERSION}-${REVISION_NUMBER}-${BUILD}.dmg"

exit 0

# EOF
