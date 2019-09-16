#!/usr/bin/env zsh -f
# Purpose: get latest version of ffmpeg
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-09-16

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

URL=$(curl -sfLS --head "https://evermeet.cx/ffmpeg/getrelease/zip" | awk -F' |\r' '/[L|l]ocation:/{print "https://evermeet.cx"$2}')

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

FFMPEG='/usr/local/bin/ffmpeg'

if [[ -x "$FFMPEG" ]]
then
	INSTALLED_VERSION=$(ffmpeg -version | awk -F' ' '/^ffmpeg /{print $3}' | tr -dc '[0-9]\.')
else
	INSTALLED_VERSION='0'
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

VERSION_COMPARE="$?"

if [ "$VERSION_COMPARE" = "0" ]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION / $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated ('$INSTALLED_VERSION' vs '$LATEST_VERSION')"

FILENAME="$HOME/Downloads/ffmpeg-${LATEST_VERSION}.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

command unzip -d "$FFMPEG:h" "$FILENAME"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip to '$FFMPEG' successful."

else
	echo "$NAME: unzip failed ($EXIT)"

	exit 1
fi

chmod 755 "$FFMPEG"

exit 0
#EOF
