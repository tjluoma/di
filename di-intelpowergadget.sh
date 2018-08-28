#!/bin/zsh -f
# Purpose: Download and install/upgrade the latest version of the Intel Power Gadget
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-27

NAME="$0:t:r"

echo "$NAME: This isn't working right because 3.5.3 and 3.5.4 seem to be the same"

exit 0

	# Yes, they really put an '(R)' in the app name. 🙄
INSTALL_TO='/Applications/Intel Power Gadget/Intel(R) Power Gadget.app'

HOMEPAGE="https://software.intel.com/en-us/articles/intel-power-gadget-20"

	# 2018-08-27 - the download link seems to be 'https://software.intel.com/file/770353/download'
	# 			but I don't know if that '770353' will change over time
DOWNLOAD_PAGE="https://software.intel.com/en-us/articles/intel-power-gadget-20"

SUMMARY="Intel Power Gadget is a software-based power usage monitoring tool enabled for Intel Core processors (from 2nd Generation up to 7th Generation Intel Core processors)."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# this just gives the part after the '10.'
	# i.e. 	for 10.11.6 it gives '11'
	# 		for 10.14 it gives '14'
OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [[ "$OS_VER" -ge "13" ]]
then

	LATEST_VERSION=$(curl -sfLS "$HOMEPAGE" | egrep "Intel® Power Gadget .* for Mac" |head -1| sed 's# for Mac<\/a>.*##g ; s#.*Intel® Power Gadget ##g')

	TEASER_URL=$(curl -sfLS "$HOMEPAGE" \
		| egrep "Intel® Power Gadget .* for Mac" \
		| head -1 \
		| sed "s#\" title=\"Intel® Power Gadget [0-9]\.[0-9]\.[0-9] for Mac\".*##g ; s#.*<a href=\"/file/#https://software.intel.com/file/#g")

	URL=$(curl --head -sfL "$TEASER_URL" \
		| awk -F' |\r' '/^.ocation/{print $2}' \
		| tail -1)

else
		# Quoting “Patrick Konsor (Intel) said on Jul 25,2018” from $HOMEPAGE:
		# 	v3.5.3 removes support for macOS pre-10.13 due to stability concerns for a limited number of users.
		# 	If you would like to install on macOS 10.12 or earlier, you can try v3.5.2: https://software.intel.com/file/641033/download
		# https://software.intel.com/sites/default/files/managed/6c/0b/Intel%C2%AE%20Power%20Gadget.dmg

		# this is for 10.12 and earlier (although I think "earlier" is capped, at 10.7 maybe? Not sure) @todo - investigate
	LATEST_VERSION="3.5.2"
	URL='https://software.intel.com/sites/default/files/managed/6c/0b/Intel%C2%AE%20Power%20Gadget.dmg'

fi

	# If either of these are blank, we cannot continue
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

FILENAME="$HOME/Downloads/IntelPowerGadget-${LATEST_VERSION}.dmg"

# no RELEASE_NOTES_URL

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

PKG=$(find "$MNTPNT" -maxdepth 1 -iname '*.pkg' -print)

if [[ "$PKG" == "" ]]
then
	echo "$NAME: Failed to find a '.pkg' file in '$MNTPNT'."
	exit 1
fi

	# IMO - this install is too complicated to do with 'unpkg.py'
	# so we'll have to settle for /usr/sbin/installer

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$PKG" && diskutil eject "$MNTPNT"
else
	sudo /usr/sbin/installer -verbose -pkg "$PKG" -dumplog -target / -lang en 2>&1 \
	&& diskutil eject "$MNTPNT" \
	|| open -a 'Installer' "$PKG"
fi

exit 0
#EOF
