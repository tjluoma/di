#!/usr/bin/env zsh -f
# Purpose: Download and install LittleSnitch version 5
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-11-14

NAME="$0:t:r"

INSTALL_TO='/Applications/Little Snitch.app'

HOMEPAGE="https://www.obdev.at/products/littlesnitch/index.html"

DOWNLOAD_PAGE="https://www.obdev.at/products/littlesnitch/download.html"

SUMMARY="As soon as you’re connected to the Internet, applications can potentially send whatever they want to wherever they want. Most often they do this to your benefit. But sometimes, like in case of tracking software, trojans or other malware, they don’t. But you don’t notice anything, because all of this happens invisibly under the hood. Little Snitch makes these Internet connections visible and puts you back in control."

 	## if you want to install beta releases
 	## create a file (empty, if you like) using this file name/path:
 	##
 	## NOTE: Not sure if this works for LittleSnitch v5 yet
 	##
# PREFERS_BETAS_FILE="$HOME/.config/di/prefers/littlesnitch-betas.txt"
#
# if [[ -e "$PREFERS_BETAS_FILE" ]]
# then
# 		This is for betas
# 	HEAD_OR_TAIL='tail'
# 	NAME="$NAME (beta releases)"
# else
# 		This is for official, non-beta versions
# 	HEAD_OR_TAIL='head'
# fi

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

XML_FEED="https://sw-update.obdev.at/update-feeds/littlesnitch5.plist"

HEAD_OR_TAIL='head'

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep -A1 "<key>ReleaseNotesURL</key>" \
	| awk -F'>|<' '/string/{print $3}' \
	| ${HEAD_OR_TAIL} -1)

INFO=($(curl -sfL "$XML_FEED" \
		| egrep -A1 'BundleShortVersionString|BundleVersion|DownloadURL' \
		| fgrep '<string>' \
		| ${HEAD_OR_TAIL} -3 \
		| sort \
		| sed 's#.*<string>##g; s#</string>##g'))

LATEST_VERSION="$INFO[1]"

LATEST_BUILD="$INFO[2]"

URL="$INFO[3]"

	# If any of these are blank, we cannot continue
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
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	echo "$NAME: Little Snitch is best updated by itself, so the app will now launch."

	open "$INSTALL_TO"

	exit 0

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/LittleSnitch-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes:" ;
	lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL"; echo '\n\n' ) \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi












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

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	echo "$NAME: moving old installed version to '$HOME/.Trash'..."
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$HOME/.Trash'. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi
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
#EOF
