#!/bin/zsh -f
# Purpose: Downloads the latest version of 1Password 7 for Mac
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-10

## Disclaimer: This script uses web page scraping, rather than an RSS/Atom/json feed, so it's prone to breaking
##				ALSO: The installer requires 'sudo' which means that it can't be run unattended
##						so it will download the pkg and then show it in Finder.

NAME="$0:t:r"

INSTALL_TO='/Applications/1Password 7.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

zmodload zsh/datetime


# URL=$(curl -sfL "https://app-updates.agilebits.com/product_history/OPM7" |\
# 		fgrep .pkg |\
# 		fgrep -vi beta |\
# 		head -1 |\
# 		sed 's#.*a href="##g; s#">download</a>##g')


DL_URL='https://app-updates.agilebits.com/download/OPM7'

URL=$(curl -sfL --head "$DL_URL" | awk -F' ' '/^.ocation: /{print $2}' | tail -1 | tr -d '\r')

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#.*1Password-##g' )

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi


	# show current version or default to '7' if not installed
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo '7.0.0'`

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Installed version $INSTALLED_VERSION is ahead of official version $LATEST_VERSION"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/1Password-${LATEST_VERSION}.pkg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0


if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME"
else
		##
		## The requirement for 'sudo' means that this script can't be run unattended, which stinks.
		## If 'sudo 'fails for some reason, we'll just show the .pkg file to the user
		##

	sudo /usr/sbin/installer -pkg "$FILENAME" -target / -lang en 2>&1 \
	|| open -R "$FILENAME"

fi
exit 0

# EOF
