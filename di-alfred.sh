#!/usr/bin/env zsh -f
# Purpose: Updated for Alfred 4
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-05-29

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	## Regular Releases
# XML_FEED='https://www.alfredapp.com/app/update4/general.xml'

	## Beta Releases
XML_FEED='https://www.alfredapp.com/app/update4/prerelease.xml'

PLIST="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM.plist"

rm -f "$PLIST"

curl -sfLS "$XML_FEED" > "$PLIST"

if [[ ! -s "$PLIST" ]]
then
	echo "$NAME: '$PLIST' is empty."
	exit 1
fi

INSTALL_TO='/Applications/Alfred 4.app'

RELEASE_NOTES=$(defaults read "${PLIST}" changelogdata)

LATEST_BUILD=$(defaults read "${PLIST}" build)

URL=$(defaults read "${PLIST}" location)

LATEST_VERSION=$(defaults read "${PLIST}" version)

	# If any of these are blank, we cannot continue
if [ "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
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

# <string>https://cachefly.alfredapp.com/Alfred_4.0_1076.tar.gz</string>

FILENAME="$HOME/Downloads/Alfred-${LATEST_VERSION}_${LATEST_BUILD}.tgz"

if (( $+commands[lynx] ))
then

	(echo "Alfred ${LATEST_VERSION} / ${LATEST_BUILD} \nURL: ${URL}\n\n$RELEASE_NOTES") | tee "$FILENAME:r.txt"

fi

## Downloading

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

## Un-Archiving

TEMPDIR=$(mktemp -d "${TMPDIR-/tmp}/$NAME.XXXXXX")

echo "$NAME: Extracting '$FILENAME' to '$TEMPDIR':"

tar -C "$TEMPDIR" -z -x -f "$FILENAME"

TEMPAPP="$TEMPDIR/Alfred 4.app"

if [[ ! -d "$TEMPAPP" ]]
then

	echo "$NAME: Did not find '$TEMPAPP'. Giving up."

	exit 1

fi

## Move old version

if [[ -e "$INSTALL_TO" ]]
then

		## the release notes for 4.0 suggests that the AppleScript syntax should be
		## 		osascript -e 'tell application "com.runningwithcrayons.Alfred" to quit'
		## but that does not actually cause Alfred 4 to quit.
		## However
		## 		osascript -e 'tell application "Alfred 4" to quit'
		## does work, so we use that
		##
		## Also `pgrep -x "Alfred 4"` does not work but `pgrep -x "Alfred"` does

		# Quit app, if running
	pgrep -xq "Alfred" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Alfred 4" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t.$INSTALLED_VERSION.app"
fi

mv -vn "$TEMPAPP" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installed new version to '$INSTALL_TO'."

	[[ "$LAUNCH" = "yes" ]] && open -g -j -a "$INSTALL_TO"

else
	echo "$NAME: failed (\$EXIT = $EXIT)"

	exit 1
fi

exit 0
#EOF
