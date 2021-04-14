#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Radio Silence <https://radiosilenceapp.com>
# Warning! Requires 'sudo installer' so it cannot be run un-attended.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-04

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/Radio Silence.app'

HOMEPAGE="http://radiosilenceapp.com"

DOWNLOAD_PAGE="http://radiosilenceapp.com/download"

SUMMARY="The easiest network monitor and firewall for Mac."

URL=$(curl -sfL "https://radiosilenceapp.com/download" \
	| awk -F'"' '/\/downloads\//{print "https://radiosilenceapp.com"$2}' \
	| head -1)

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

	# If any of these are blank, we should not continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"
	exit 1
fi

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

# No RELEASE_NOTES_URL available ☹️

FILENAME="$HOME/Downloads/$URL:t"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$FILENAME"
else
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en
fi

exit 0
#EOF
