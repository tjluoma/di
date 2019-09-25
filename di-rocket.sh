#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Rocket from <https://matthewpalmer.net/rocket/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-09; major update 2019-09-25


## 2019-09-25 there are two of these. They both seem current. The former has 1 release missing from the latter.
# https://macrelease.matthewpalmer.net/distribution/appcasts/rocket.xml
# https://updates.devmate.com/net.matthewpalmer.Rocket.xml

## Beta also uses DMG not zip so I'm not including support for it at the moment
## https://macrelease.matthewpalmer.net/distribution/appcasts/rocket.xml?beta=true
## https://macrelease.matthewpalmer.net/distribution/appcasts/rocket-beta.xml
# NAME="$NAME (betas)"
# XML_FEED='https://macrelease.matthewpalmer.net/distribution/appcasts/rocket.xml?beta=true'
# HEADS_OR_TAILS='tail'

	# https://macrelease.matthewpalmer.net/distribution/appcasts/rocket.xml?beta=false
	# https://macrelease.matthewpalmer.net/distribution/appcasts/rocket.xml


if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

INSTALL_TO="/Applications/Rocket.app"

HOMEPAGE="https://matthewpalmer.net/rocket/"

DOWNLOAD_PAGE="https://matthewpalmer.net/rocket/"

SUMMARY="The fastest, smoothest Slack-style emoji picker for your Mac."

XML_FEED='https://macrelease.matthewpalmer.net/distribution/appcasts/rocket.xml'

# RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
# 	| fgrep '<sparkle:releaseNotesLink>' \
# 	| head -1 \
# 	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')
#
# INFO=($(curl -sfL "$XML_FEED" \
# 		| egrep '(<enclosure url="https://.*\.zip")' \
# 		| head -1 \
# 		| tr ' ' '\012' \
# 		| sort \
# 		| egrep 'url=|sparkle:version=|sparkle:shortVersionString=' \
# 		| awk -F'<|>|"' '//{print $2}'))
#
# LATEST_VERSION="$INFO[1]"
# LATEST_BUILD="$INFO[2]"
# URL="$INFO[3]"


	## 2019-09-25 - ok, I noticed this once before and wrote it off as a fluke, but it's happened
	## twice now, so I guess it's a pattern.
	##
	## Sometimes the newest release is added to the BOTTOM of the XML_FEED
	## but sometimes it is added at the top.
	##
	## The only reliable way to tell what is the newest version is to look at all of the entries
	## in the feed, and look at the 'sparkle:version' number for each. That has been more reliable
	## than the other version number even, because it gets incremented with no decimal
	## which makes comparing build numbers much easier.
	##
	## So here's what I've done

	## create a random tempfile
TEMPFILE="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM.$RANDOM.xml"

	## curl = fetch  the XML file
	## egrep = remove any references to 'delta' builds
	## tr = delete all newlines and tabs (this makes the while input one long line )
	## sed
	## 		= delete eveerything up to </language>
	##		= delete </channel></rss>
	##		= replace </item> with </item> followed by a newline
	## save the final output to that temp file

curl -sfLS "$XML_FEED" \
| egrep -vi '<sparkle:deltas>|</sparkle:deltas>|\.delta" ' \
| tr -d '\012|\t' \
| sed \
	-e 's#.*</language>##g' \
	-e 's#</channel></rss>##g' \
	-e 's#</item>#</item>\
#g' \
> "$TEMPFILE"


	## Look at all of the lines for only the number defined as `sparkle:version=`
	## sort all of the numbers in a numeric sort
	## and take the last one which should be the highest number
LATEST_BUILD=$(sed -e 's#.* sparkle:version="##g' -e 's#" .*##g' "$TEMPFILE" | sort --numeric-sort | tail -1)

	## now get the entire line that matches that particular `sparkle:version=` number and save it as $INFO
INFO=$(fgrep "sparkle:version=\"$LATEST_BUILD\"" "$TEMPFILE")

	## get just the `sparkle:shortVersionString` from $INFO
LATEST_VERSION=$(echo "$INFO" | sed 's#.* sparkle:shortVersionString="##g; s#" .*##g')

	## get just the `<enclosure url` from $INFO
URL=$(echo "$INFO" | sed 's#.*<enclosure url="##g; s#" .*##g')

	## get just the `sparkle:releaseNotesLink` from $INFO
RELEASE_NOTES_URL=$(echo "$INFO" | sed 's#.*<sparkle:releaseNotesLink>##g; s#</sparkle:releaseNotesLink>.*##g')

# echo "
# Version: $LATEST_VERSION
#   Build: $LATEST_BUILD
#     URL: $URL
#   Notes: $RELEASE_NOTES_URL
# "

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

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

	## here's another thing that has changed, and I don't know which way it's going to go in the future:
	## sometimes the download is a .zip and sometimes it's a DMG
	## so we look at the end of the URL to determine which file extension to give our '$FILENAME'

EXT=$(echo "$URL:e:l")

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.$EXT"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Release Notes from '$RELEASE_NOTES_URL' are too long to show, saving them to '$FILENAME:r.html'." | tee "$FILENAME:r.txt"

curl -sfLS "$RELEASE_NOTES_URL" >| "$FILENAME:r.html"

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"


## OK, so now we have a valid download, but is it a ZIP or a DMG? We don't know!
## So we'll leave options for either, and take action depending on which extension we have


if [[ "$EXT" == "dmg" ]]
then

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
		mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

		EXIT="$?"

		if [[ "$EXIT" != "0" ]]
		then

			echo "$NAME: failed to move '$INSTALL_TO' to Trash. ('mv' \$EXIT = $EXIT)"

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

	echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"


elif [[ "$EXT" == "zip" ]]
then

		## make sure that the .zip is valid before we proceed
	(command unzip -l "$FILENAME" 2>&1 )>/dev/null

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then
		echo "$NAME: '$FILENAME' is a valid zip file."

	else
		echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

		mv -fv "$FILENAME" "$HOME/.Trash/"

		mv -fv "$FILENAME:r".* "$HOME/.Trash/"

		exit 0

	fi

	## unzip to a temporary directory
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

else

	echo "$NAME: '$EXT' is neither 'dmg' nor 'zip'. Giving up."
	exit 1

fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
