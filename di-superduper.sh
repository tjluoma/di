#!/bin/zsh -f
# Purpose: Download and install the latest version of SuperDuper
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

INSTALL_TO='/Applications/SuperDuper!.app'

HOMEPAGE="https://www.shirt-pocket.com/SuperDuper/SuperDuperDescription.html"

DOWNLOAD_PAGE="https://www.shirt-pocket.com/downloads/SuperDuper%21.dmg"

SUMMARY="SuperDuper is the wildly acclaimed program that makes recovery painless, because it makes creating a fully bootable backup painless. Its incredibly clear, friendly interface is understandable, easy to use, and SuperDuper's built-in scheduler makes it trivial to back up automatically. It's the perfect complement to Time Machine, allowing you to store a bootable backup alongside your Time Machine volume—and it runs beautifully on your Mac!"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS")

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

	OS_VER=`sw_vers -productVersion`

	OS_BUILD=`sw_vers -buildVersion`

	# Example:
	# http://versioncheck.blacey.com/superduper/Version.xml?VSN=96,10.11.1(15B42)

	XML_FEED="http://versioncheck.blacey.com/superduper/Version.xml?VSN=$INSTALLED_VERSION,$OS_VER($OS_BUILD)"

else

	XML_FEED="http://versioncheck.blacey.com/superduper/Version.xml"

fi


## The other version info (other than 'CFBundleVersion') isn't present in XML_FEED

INFO=($(curl -sfL "$XML_FEED" \
		| egrep -A1 '<key>version</key>|<key>downloadURL</key>' \
		| fgrep '<string>' \
		| sed 's#</string>##g ; s#.*<string>##g'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/SuperDuper-${LATEST_VERSION}.tar.gz"

## Release Notes BEGIN

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| fgrep -A1 '<key>infoURL</key>' \
		| fgrep 'http' \
		| sed 's#.*<string>## ; s#</string>##g')

( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):" ;
	curl -sfL "$RELEASE_NOTES_URL" \
		| textutil -convert txt -stdin -stdout \
		| sed 's#	•	# * #g ; s#  # #g' ;
	echo "\nSource: <${RELEASE_NOTES_URL}>" ) | tee -a "$FILENAME:r.txt"

## Release Notes END

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/SuperDuper!.$INSTALLED_VERSION.app"
fi

TEMPDIR=`mktemp -d "${TMPDIR-/tmp}/$NAME.XXXXXX"`

echo "$NAME: Extracting $FILENAME to $TEMPDIR:"

tar -C "$TEMPDIR" -z -x -f "$FILENAME"

PKG=`find "$TEMPDIR" -iname \*.pkg -maxdepth 1 -print`

if [[ "$PKG" == "" ]]
then
	echo "$NAME [failed]: PKG is empty" \
	| tee -a "$HOME/Desktop/$NAME.Failed.log"

	exit 0
fi

pgrep -q -x 'SuperDuper!'  && (echo "$NAME: SuperDuper! is running, cannot install." | tee -a "$HOME/Desktop/$NAME.log" ) && exit 0

echo "$NAME: Preparing to install $PKG"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$PKG"
else

	if [ "$EUID" = "0" ]
	then
		/usr/sbin/installer -pkg "$PKG" -target / -lang en

	else
			# Try sudo but if it fails, open pkg in Finder
		sudo /usr/sbin/installer -pkg "$PKG" -dumplog -target / -lang en \
		|| open -R "$PKG"
	fi
fi

## I don't know why it ends up installed here, but it does

APP_TEMP='/tmp/superduper_install/SuperDuper!.app'

if [ -e "$APP_TEMP" -a ! -e "$INSTALL_TO" ]
then
	mv -v "$APP_TEMP" "$INSTALL_TO" \
	|| sudo mv -v "$APP_TEMP" "$INSTALL_TO"

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	mv -vf "$FILENAME" "$FILENAME:h/SuperDuper-${INSTALLED_VERSION}_${INSTALLED_BUILD}.tar.gz"

	mv -vf "$FILENAME:r.txt" "$FILENAME:h/SuperDuper-${INSTALLED_VERSION}_${INSTALLED_BUILD}.txt"

fi

exit 0
#EOF
