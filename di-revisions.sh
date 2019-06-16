#!/bin/zsh -f
# Purpose: Download and install latest version of Revisions
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

INSTALL_TO='/Applications/Revisions.app'

HOMEPAGE="https://www.revisionsapp.com/"

DOWNLOAD_PAGE="https://www.revisionsapp.com/#extraContainer5"

SUMMARY="The Mac OS X app that displays all your Dropbox edits, shows exactly what changes were made, and provides unlimited undo going back 30 days (or more)."

RELEASE_NOTES_URL='https://www.revisionsapp.com/releases'

URL=$(curl -sfL https://www.revisionsapp.com | fgrep '.dmg' | sed "s#.*downloads/#https://www.revisionsapp.com/downloads/#g ; s#'\;##g ; s# ##g")

FILENAME="$HOME/Downloads/$URL:t"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# NOTE: "https://revisionsapp.com/releases" is not an XML_FEED

if [ -e "$INSTALL_TO" ]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	XML_FEED="http://www.revisionsapp.com/checkforupdate/web/$INSTALLED_VERSION"

	##########################################################################################
	## This feed gives a very small amount of information, such as this:
	##
	# 	{
	# 	  "updateAvailable": 0,
	# 	  "noUpdateAvailable": 1,
	# 	  "latestVersion": "3.0.1"
	# 	}
	##########################################################################################

	LATEST_VERSION=`curl -sfL "$XML_FEED" | awk -F'"' '/latestVersion/{print $4}'`

		# If any of these are blank, we should not continue
	if [ "$LATEST_VERSION" = "" ]
	then
		echo "$NAME: Error: bad data received:\nLATEST_VERSION: $LATEST_VERSION"
		exit 0
	fi

	 if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
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

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

		# NOTE! We are GUESSING here, because the feed does not actually contain the
		# download URL. This relies on the developer not changing the website

		# Look to see if there is a DMG listed in the HTML of the page
	SHORT_URL=`curl -sfL https://www.revisionsapp.com | fgrep -i '.dmg' | awk -F"'" '//{print $2}'`

	if [[ "$SHORT_URL" == "" ]]
	then
			# If we did NOT find anything, try to guess that the developer used the same naming
			# convention as currently in use when this script was written
		URL="https://www.revisionsapp.com/downloads/revisions-$LATEST_VERSION.dmg"
	else
			# If we DID find something, use it
			## NOTE! This assumes that the SHORT_URL is a relative one
		URL="https://www.revisionsapp.com${SHORT_URL}"
	fi

	HTTP_STATUS=`curl --head -sfL "$URL" | awk -F' ' '/HTTP/{print $2}'`

	if [[ "$HTTP_STATUS" != "200" ]]
	then

		echo "$NAME: $INSTALL_TO is out of date ($INSTALLED_VERSION vs $LATEST_VERSION) but URL is not correct $URL" \
		| tee -a "$HOME/Desktop/$NAME.error.log"

		exit 0
	else
		echo "$NAME: Out of Date: $INSTALLED_VERSION vs $LATEST_VERSION"
	fi

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/revisions-for-dropbox/id819348619?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/revisions-for-dropbox/id819348619>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

	FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

fi
# IF installed

if (( $+commands[lynx] ))
then

	alias mytidy='tidy --char-encoding utf8 --wrap 0 --show-errors 0 --indent no --input-xml no \
		--output-xml no --quote-nbsp no --show-warnings no --uppercase-attributes no \
		--uppercase-tags no --clean yes --force-output yes --join-classes yes --join-styles yes \
		--markup yes --output-xhtml yes --quiet yes --quote-ampersand yes --quote-marks yes'

	SECOND_VERSION=$(curl -sfL "${RELEASE_NOTES_URL}" \
	| mytidy \
	| egrep '<h5>.*</h5>' \
	| sed -n '2p' \
	| sed 's#<\/h5>#<\\/h5>#g')

	echo -n "$NAME: Release Notes for $INSTALL_TO:t:r Version "

	# For some reason, trying to use 'mytidy' below did not work, so I just copied it again. ¯\_(ツ)_/¯

	( curl -sfL "${RELEASE_NOTES_URL}" \
		| tidy --char-encoding utf8 --wrap 0 --show-errors 0 --indent no \
			--input-xml no --output-xml no --quote-nbsp no --show-warnings no --uppercase-attributes no \
			--uppercase-tags no --clean yes --force-output yes --join-classes yes --join-styles yes \
			--markup yes --output-xhtml yes --quiet yes --quote-ampersand yes --quote-marks yes \
		| sed '1,/RETURN TO MAIN PAGE/d' \
		| sed "/$SECOND_VERSION/,\$d" \
		| sed '1,/<br \/>/d ; s#<hr \/>##g' \
		| egrep -i '.' \
		| uniq \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	# This will agree to the EULA for you without you reading it
	# If you do not want that, don't use this script
MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"
		exit 1
	fi
fi

echo "$NAME: installing $MNTPNT/$INSTALL_TO:t to $INSTALL_TO"

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installed $INSTALL_TO successfully"

	[[ "$LAUNCH" == "yes" ]] && open "$INSTALL_TO" && echo "$NAME: re-launched $INSTALL_TO"

	diskutil eject "$MNTPNT"

else
	echo "$NAME: Installation failed (\$EXIT = $EXIT)"

fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#
#EOF
