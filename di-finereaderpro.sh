#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of Fine Reader Pro
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2015-11-09 ; 2019-11-14 update ; 2020-01-31 ne URL and method of downloading
# Verified:	2025-02-24


# Chcek for Updates opens this page
# https://pdf.abbyy.com/checkforupdates/?Product=FineReaderMac&Distributive=Retail&Revision=FSRR15000007037407926727&Language=en&PartNumber=1402.19&Target=CheckUpdate&Version=15.2&Revision=14&Build=1093332
#######################################################################################

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/ABBYY FineReader PDF.app'

if [[ -e "$INSTALL_TO" ]]
then
	echo "$NAME Fatal error: '$INSTALL_TO' already exists.\n\tI can only install, not update."
	exit 0
fi

URL=$(curl -sfLS "https://www.abbyy.com/finereader-pdf-mac-downloads/" \
		| tr ' ' '\012' \
		| fgrep -i .dmg \
		| sed 's#href="##g; s#"$##g' \
		| head -1)

FILENAME="$HOME/Downloads/FineReader.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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
else
	echo "$NAME: MNTPNT is $MNTPNT"
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

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0

# EOF