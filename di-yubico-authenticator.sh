#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of Yubico Authenticator
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-09-25

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Yubico Authenticator.app'

ROOT_URL='https://developers.yubico.com/yubioath-desktop/Releases'

RELEASE_NOTES_URL='https://developers.yubico.com/yubioath-desktop/Release_Notes.html'

LATEST_FILE=$(curl -sfLS "$ROOT_URL" \
		| tr '"|>|<' '\012' \
		| egrep '\.pkg$' \
		| head -1)

URL="$ROOT_URL/$LATEST_FILE"

LATEST_VERSION=$(echo "$LATEST_FILE:t:r" | tr -dc '[0-9]\.')

	# If any of these are blank, we cannot continue
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

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.pkg"

if (( $+commands[lynx] ))
then

	( curl -sfLS "$RELEASE_NOTES_URL" \
	| awk '/^Version /{i++}i==1' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist ; \
	echo "\nRelease Notes URL: $RELEASE_NOTES_URL\nURL: $URL" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME"

else

	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en | tee -a "$FILENAME:r.install.log" || open -R "$FILENAME"
fi

exit 0
#EOF
