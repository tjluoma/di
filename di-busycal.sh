#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of BusyCal
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2015-11-10
# Verified:	2025-02-24

NAME="$0:t:r"

INSTALL_TO='/Applications/BusyCal.app'

HOMEPAGE="https://www.busymac.com/busycal/index.html"

DOWNLOAD_PAGE="http://www.busymac.com/download/BusyCal.zip"

SUMMARY="BusyCal 3 is the most powerful, flexible, reliable calendar app for macOS. It's packed with time-saving features and compatible with all leading cloud services including iCloud, Google, Exchange and more."

RELEASE_NOTES_URL='https://www.busymac.com/busycal/releasenotes.html'

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

function die
{
	echo "$NAME: $@"
	exit 1
}

# curl -sfL http://versioncheck.busymac.com/busycal/news.plist

URL='http://www.busymac.com/download/BusyCal.zip'

LATEST_VERSION=`curl -sfL http://versioncheck.busymac.com/busycal/news.plist\
				| fgrep -A1 '<key>current</key>' \
				| fgrep '<string>' \
				| head -1 \
				| tr -dc '[0-9].'`

LATEST_BUILD=`curl -sfL http://versioncheck.busymac.com/busycal/news.plist\
				| fgrep -A1 '<key>currentbuild</key>' \
				| fgrep '<string>' \
				| head -1 \
				| tr -dc '[0-9].'`


	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" -o "$LATEST_BUILD" = "" ]
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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/busycal/id1173663647?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/busycal/id1173663647>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

	# What we download is a .zip file with a .pkg file inside of it,
	# so we first need to unzip the .zip file and then install the .pkg file

# FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"
FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.zip"
	PKG="$FILENAME:h/$INSTALL_TO:t:r-$LATEST_VERSION.pkg"

if (( $+commands[lynx] ))
then

	( echo -n "$NAME: Release Notes for " ;
	curl -sfL "$RELEASE_NOTES_URL" \
	| sed '1,/<div class="release-notes">/d; /<div class="release-notes">/,$d' \
	| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt"

EXIT="$?"

if [[ "$EXIT" == "1" ]]
then

	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"

fi

if [ -e "$INSTALL_TO" -a ! -w "$INSTALL_TO" ]
then
	echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

	exit 2
fi

cd "$FILENAME:h"

# This is where we
# unzip the .zip
# move the .zip to the trash
# rename the .pkg according to how we want it named

ditto --noqtn -xk -V --rsrc --extattr "$FILENAME" . || die "ditto failed"

mv -f "$FILENAME" "$HOME/.Trash/"

mv -vf "BusyCal Installer.pkg" "$PKG" || die "Rename of $PKG failed"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$PKG" || die "pkginstall.sh failed"

else

	sudo /usr/sbin/installer -pkg "$PKG" -target / -lang en 2>&1 || die "sudo installer failed"

fi

NEWLY_INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

echo "$NAME: Successfully installed $INSTALL_TO:t:r '$NEWLY_INSTALLED_VERSION'."

exit 0

#
#EOF
