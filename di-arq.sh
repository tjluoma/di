#!/usr/bin/env zsh -f
# Purpose: download and install Arq 7
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-02-03

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Arq.app'

JSON_FEED_URL='https://www.arqbackup.com/download/arqbackup/arq7_update.json'

INFO=($(curl -sfLS "${JSON_FEED_URL}" \
		| egrep '"(url|version)"' \
		| sort \
		| awk -F'"' '//{print $4}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	" >>/dev/stderr

	exit 1
fi

###############################################################################################

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [[ "$VERSION_COMPARE" == "0" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

###############################################################################################

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.pkg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

RELEASE_NOTES_HTML="$FILENAME:r.html"

if [[ -e "${RELEASE_NOTES_TXT}" ]]
then

	cat "${RELEASE_NOTES_TXT}"

else

	if (( $+commands[lynx] ))
	then

			# has full history of v7 updates
		RELEASE_NOTES_URL='https://www.arqbackup.com/download/arqbackup/arq7_release_notes.html'

		TEMPFILE="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.txt"

		curl -sfLS "${RELEASE_NOTES_URL}" > "$RELEASE_NOTES_HTML"

		fgrep '<h1>' "${RELEASE_NOTES_HTML}" | cat -n > "${TEMPFILE}"

		AWK_NUMBER=$(fgrep "${LATEST_VERSION}" "${TEMPFILE}" | awk '{print $1}')

		RELEASE_NOTES=$(awk "/<h1>/{i++}i==$AWK_NUMBER" "${RELEASE_NOTES_HTML}" \
				| lynx 	-dump -width='10000' -display_charset=UTF-8 \
						-assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins \
				| sed 's#^[ 	]*##g' )

		echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nVersion: ${LATEST_VERSION}\nURL: ${URL}" \
		| tee "${RELEASE_NOTES_TXT}"

	fi

fi

###############################################################################################

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

###############################################################################################

if (( $+commands[pkginstall.sh] ))
then
		# use 'pkginstall.sh' if it exists

	pkginstall.sh "$FILENAME"

else
		# fall back to either `sudo installer` or macOS's installer app
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1 \
	|| open -b com.apple.installer "$FILENAME"

fi

exit 0
#EOF
