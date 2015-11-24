#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-09

# DON'T SHARE as it has your serial # in it! 

SN='FSAR12000003434597579774'

INSTALL_TO='/Applications/FineReader.app'
# 

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi


if [ -e "$INSTALL_TO" ]
then


	TEMPFILE="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM"


	BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion`

	MAJOR_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d . -f 1,2`

	REVISION_NUMBER=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d . -f 3`

	URL="http://www.abbyy.com/checkforupdates/?Product=FRProMac&Distributive=Retail&Serial=${SN}&Language=en&PartNumber=1215%2f10&Target=CheckUpdate&Version=${MAJOR_VERSION}&Revision=${REVISION_NUMBER}&Build=${BUILD}"

	rm -f "$TEMPFILE"

	curl -sfL "$URL"  > "$TEMPFILE"
	
	if (fgrep -qi 'There are no updates currently available' "$TEMPFILE")
	then
		echo "$NAME: No Update Available"
		exit 0
	elif (fgrep -i 'Download update' "$TEMPFILE")
	then
		echo "$NAME: Update Available"
	else
		echo "$NAME: Unable to tell if an update is available"
		open "$URL"
		exit 0
	fi 	

fi


## If we get here, either an update is available or the app isn't installed at all 

FILENAME="$HOME/Downloads/ABBYY_FineReader_Pro_ESD.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "http://fr7.abbyy.com/mac/fr/ABBYY_FineReader_Pro_ESD.dmg"


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "FineReader" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "FineReader" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/FineReader.$INSTALLED_VERSION.app"
fi

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

ditto -v "$MNTPNT/FineReader.app" "$INSTALL_TO"

diskutil eject "$MNTPNT"


# Rename the downloaded file based on the version number we leanre
NEW_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

[[ "$NEW_VERSION" != "" ]] && 
	mv -fv "$FILENAME" "$FILENAME:h/FineReader-$NEW_VERSION.dmg"


exit 0

# http://www.abbyy.com/checkforupdates/?Product=FRProMac&Distributive=Retail&Serial=FSAR12000003434597579774&Language=en&PartNumber=1215%2f8&Target=CheckUpdate&Version=12.1&Revision=3&Build=622395
# 
# defaults read /Applications/FineReader.app/Contents/Info |f version

#     CFBundleShortVersionString = "12.1.3";

#     CFBundleVersion = 622395;

# Latest version always =  ?

#EOF
