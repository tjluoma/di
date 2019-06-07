#!/bin/zsh -f
# Purpose: get the latest https://www.soma-zone.com/BackupLoupe/
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-06

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://www.soma-zone.com/BackupLoupe/a/appcast_update.xml'

INSTALL_TO='/Applications/BackupLoupe.app'

TEMPFILE="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM.xml"

rm -f "$TEMPFILE"

curl -sfLS "$XML_FEED" > "$TEMPFILE" || exit 1

ITEM_COUNT=$(fgrep '<item>' "$TEMPFILE" |wc -l | tr -dc '[0-9]')

INFO=$(awk "/<item>/{i++}i==${ITEM_COUNT}" "$TEMPFILE")

VERSIONS=($(echo "$INFO" | tr -s ' |\t' '\012' | egrep 'sparkle:(version=|shortVersionString)' | sort | awk -F'"' '//{print $2}'))

LATEST_VERSION="$VERSIONS[1]"

LATEST_BUILD="$VERSIONS[2]"

URL=$(echo "$INFO" | awk -F'"' '/url=/{print $2}')

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.tbz2"

if (( $+commands[lynx] ))
then

	(echo "$INSTALL_TO:t:r $LATEST_VERSION / $LATEST_BUILD";echo "${INFO}" \
	| sed '1,/<description>/d; /<\/description>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nonumbers -nolist -stdin ) \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Installing $FILENAME to $UNZIP_TO"

tar -x -C "$UNZIP_TO" -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" != "0" ]
then
	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)"
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

	# move the app from the temp folder to the regular installation dir
mv -vf "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then

	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"


exit 0
#EOF
