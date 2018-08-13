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

	# create a file (empty, if you like) at "$HOME/.config/di/1Password-prefer-betas.txt"
	# if you want to install beta releases
if [[ -e "$HOME/.config/di/1Password-prefer-betas.txt" ]]
then
	URL=$(curl -sfL "https://app-updates.agilebits.com/product_history/OPM7" |\
 		fgrep .pkg |\
 		fgrep -i beta |\
 		head -1 |\
 		sed 's#.*a href="##g; s#">download</a>##g')

	LATEST_VERSION=$(echo "$URL:t:r" | sed 's#.*1Password-##g' )

	NAME="$NAME (beta releases)"

	BETAS='yes'
else
	BETAS='no'

	DL_URL='https://app-updates.agilebits.com/download/OPM7'

	URL=$(curl -sfL --head "$DL_URL" | awk -F' |\r' '/^.ocation: /{print $2}' | tail -1)

	LATEST_VERSION=$(echo "$URL:t:r" | sed 's#.*1Password-##g' )
fi

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

if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
then
	echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
	echo "$NAME: Please use the App Store app to update $INSTALL_TO."
	exit 0
fi

if (( $+commands[lynx] ))
then

	if [ "$BETAS" = 'yes' ]
	then

		RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

		echo -n "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION)"

		curl -sfL "$RELEASE_NOTES_URL" \
		| sed "1,/class='beta'/d; /<article /,\$d" \
		| sed '1,/<\/h3>/d' \
		| lynx -dump -nomargins -width='100' -assume_charset=UTF-8 -pseudo_inlines -stdin

		echo "\nSource: <$RELEASE_NOTES_URL>"

	else

		RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

		echo -n "$NAME: Release Notes for $INSTALL_TO:t:r"

		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<article id="v[0-9]*"[ ]*>/d; /<\/article>/,$d' \
		| egrep -vi '1Password never prompts you for a review|If you need us, you can find us at|<a href="https://c.1password.com/dist/1P/mac7/.*">download</a>' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| sed '/./,/^$/!d'
		# sed delete blank lines at start of file

		echo "\nSource: <$RELEASE_NOTES_URL>"
	fi

fi

FILENAME="$HOME/Downloads/1Password-${LATEST_VERSION}.pkg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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


## Another way of getting the URL. Still works (2018-08-07). Keeping as backup.
# URL=$(curl -sfL "https://app-updates.agilebits.com/product_history/OPM7" |\
# 		fgrep .pkg |\
# 		fgrep -vi beta |\
# 		head -1 |\
# 		sed 's#.*a href="##g; s#">download</a>##g')
# EOF
