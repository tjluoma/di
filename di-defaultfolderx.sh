#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Default Folder X
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-05

NAME="$0:t:r"

INSTALL_TO='/Applications/Default Folder X.app'

HOMEPAGE="https://stclairsoft.com/DefaultFolderX/index.html"

DOWNLOAD_PAGE="https://www.stclairsoft.com/cgi-bin/dl.cgi?DX"

SUMMARY="Make your Open and Save dialogs work as quickly as you do."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# if you want to install beta releases
	# create a file (empty, if you like) using this file name/path:


	# if we find the old prefer-beta file, move it to the new place
OLD_PREFERS_BETAS_FILE="$HOME/.config/di/defaultfolderx-prefer-betas.txt"
PREFERS_BETAS_FILE="$HOME/.config/di/prefers/defaultfolderx-prefer-betas.txt"

[[ ! -d "$PREFERS_BETAS_FILE:h" ]] && mkdir "$PREFERS_BETAS_FILE:h"

if [[ -e "$OLD_PREFERS_BETAS_FILE" ]]
then
	if [[ -e "$PREFERS_BETAS_FILE" ]]
	then
			# if the new betas file exists, just delete the old one
		rm -f "$OLD_PREFERS_BETAS_FILE"
	else
			# if the new betas file does NOT exist, move the old one to the new place.
		mv -vf "$OLD_PREFERS_BETAS_FILE" "$PREFERS_BETAS_FILE"
	fi
fi

if [[ -e "$PREFERS_BETAS_FILE" ]]
then
		# This is for betas
	URL=$(curl -sfL 'http://www.stclairsoft.com/cgi-bin/dl.cgi?DX-B' \
		| egrep -i '<META HTTP-EQUIV="Refresh" CONTENT="0;URL=' \
		| sed 's#.*https#https#g; s#.dmg.*#.dmg#g')

	## This is another way of calculating the URL from the same page
	#WEB_SCRAPING_URL=$(curl -sfL 'http://www.stclairsoft.com/cgi-bin/dl.cgi?DX-B' \
	#	| tr -s '"|\047|=' '\012' \
	#	| egrep '^https.*\.dmg' \
	#	| tail -1)

	LATEST_VERSION=$(echo "$URL:t:r" | sed 's#DefaultFolderX-##g' )

	NAME="$NAME (beta releases)"

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

	RELEASE_NOTES_URL="https://www.stclairsoft.com/DefaultFolderX/beta.html"

	FILENAME="$HOME/Downloads/DefaultFolderX-beta-${LATEST_VERSION}.dmg"

	( echo "$NAME: Release Notes for Default Folder X:" ;
	curl -sfL "$RELEASE_NOTES_URL" \
	| sed '1,/<!-- InstanceBeginEditable name="main editable" -->/d; /<H3>How to be a beta tester:<\/H3>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"


else

		# This is the URL actually given by the feed itself
		# 	XML_FEED='http://www.stclairsoft.com/updates/DefaultFolderX5.xml'
		# but this is the URL found in the app itself
	XML_FEED='https://www.stclairsoft.com/cgi-bin/sparkle.cgi?DX5'

	if [[ -e "$INSTALL_TO" ]]
	then

		INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

		INSTALLED_BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion`

			# User Agent = Default Folder X/5.0b1 Sparkle/58
		UA="Default Folder X/$INSTALLED_VERSION Sparkle/$INSTALLED_BUILD"

	else
			# This is current info as of 2018-08-02
		UA="Default Folder X/5.2.5 Sparkle/483"
	fi

	INFO=($(curl -sfL -A "$UA" "$XML_FEED" \
			 | tr -s ' ' '\012' \
			 | egrep '^(sparkle:shortVersionString|url|sparkle:version)=' \
			 | sort \
			 | head -3 \
			 | awk -F'"' '//{print $2}'))

	## Expected output something like:
	#
	# 5.2.5
	# 483
	# https://www.stclairsoft.com/download/DefaultFolderX-5.2.5.dmg

	LATEST_VERSION="$INFO[1]"
	LATEST_BUILD="$INFO[2]"
	URL="$INFO[3]"

	if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$LATEST_BUILD" = "" ]
	then
		echo "$NAME Error: bad data received:
		INFO: $INFO
		LATEST_VERSION: $LATEST_VERSION
		LATEST_BUILD: $LATEST_BUILD
		URL: $URL\n"

		exit 1
	fi

	if [[ -e "$INSTALL_TO" ]]
	then

		if [[ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]]
		then
			echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
			exit 0
		fi

		autoload is-at-least

		is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

		if [ "$?" = "0" ]
		then
			echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
			exit 0
		fi

		echo "$NAME: Outdated (Installed = $INSTALLED_BUILD vs Latest = $LATEST_VERSION)"

	fi

	FILENAME="$HOME/Downloads/DefaultFolderX-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| sed '1,/<sparkle:releaseNotesLink xml:lang="en">/d; /<\/sparkle:releaseNotesLink>/,$d' \
		| tr -d '[:blank:]')

		( echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION/$LATEST_BUILD: \n" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<h3>/d; /<h3>/,$d' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <${RELEASE_NOTES_URL}>" ) | tee "$FILENAME:r.txt"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "Default Folder X" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Default Folder X" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Default Folder X.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

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
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

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

[[ "$LAUNCH" = "yes" ]] && echo "$NAME: Re-Launching '$INSTALL_TO':"  && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: "

diskutil eject "$MNTPNT"

if (is-growl-running-and-unpaused.sh)
then
	growlnotify \
	--appIcon "Default Folder X" \
	--identifier "$NAME" \
	--message "Updated to $LATEST_VERSION" \
	--title "$NAME"
fi

exit 0
#EOF
