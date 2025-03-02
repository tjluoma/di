#!/usr/bin/env zsh -f
# Purpose: 	Download and install Arq 7
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2021-02-03
# Verified:	2025-03-02

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

	# this is installed via .pkg so will always end up in /Applications/
INSTALL_TO="/Applications/Arq.app"

NAME="$0:t:r"

	## this has the filename and version of the latest updates - @TODO
	# https://www.arqbackup.com/download/arqbackup/arq7_release_notes.html
	## possibly this URL format:
	#https://www.arqbackup.com/download/arqbackup/ArqUpdate7.16.pkg

	## 2025-03-02 - this is outdated and apparently not used anymore.
	## This says 7.16 from 2022 when we're on 7.35 and many updates since in 2025

RELEASE_NOTES_URL='https://www.arqbackup.com/download/arqbackup/arq7_release_notes.html'

INFO=($(curl -sfLS "$RELEASE_NOTES_URL" \
		|awk '/<h1>/{i++}i==1'))

LATEST_VERSION=$(echo "$INFO" | fgrep '.pkg' | sed 's#.*(Arq##g ; s#.pkg).*##g')

	# static URL from https://www.arqbackup.com/download/ 2025-03-02
URL="https://www.arqbackup.com/download/arqbackup/Arq7.pkg"

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

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.pkg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

RELEASE_NOTES_HTML="$FILENAME:r.html"

if [[ -e "${RELEASE_NOTES_TXT}" ]]
then

	cat "${RELEASE_NOTES_TXT}"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(echo "$INFO" \
				| lynx 	-dump -width='10000' -display_charset=UTF-8 \
						-assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins )

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
