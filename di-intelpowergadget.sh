#!/usr/bin/env zsh -f
# Purpose: Download and install/upgrade the latest version of the Intel Power Gadget
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-27

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# Yes, they really put an '(R)' in the app name. 🙄
	# Installed via pkg
INSTALL_TO='/Applications/Intel Power Gadget/Intel(R) Power Gadget.app'

HOMEPAGE="https://software.intel.com/en-us/articles/intel-power-gadget"

DOWNLOAD_PAGE="$HOMEPAGE"

SUMMARY="Intel Power Gadget is a software-based power usage monitoring tool enabled for Intel Core processors (from 2nd Generation up to 7th Generation Intel Core processors)."

	# this just gives the part after the '10.'
	# i.e. 	for 10.11.6 it gives '11'
	# 		for 10.14 it gives '14'
OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [[ "$OS_VER" -ge "13" ]]
then

		## 2019-09-28 - yes the file URL changed. That is not a huge surprise, but it means we are reduced to HTML scraping
		## The old URL was https://software.intel.com/en-us/articles/intel-power-gadget-20
		# 2018-08-27 - the download link seems to be 'https://software.intel.com/file/770353/download'
		# 			but I don't know if that '770353' will change over time
		# 2019-05-23 - it looks like the URL _has_ changed, but I'm not sure if that's because the HOMEPAGE changed too
		# 2019-06-30 - this URL no longer seems to be the one that is used (see footnote) but it still works, for now.
	# URL=$(curl -sfL --head 'https://software.intel.com/file/778485/download' | awk -F' ' '/^Location:/{print $NF}' | tr -d '[:cntrl:]')

	URL1=$(curl -sfLS "$HOMEPAGE" \
			| tidy --tidy-mark no --char-encoding utf8 --wrap 0 --show-errors 0 --indent no --input-xml no --output-xml no \
			--quote-nbsp no --show-warnings no --uppercase-attributes no --uppercase-tags no --clean yes --force-output yes \
			--join-classes yes --join-styles yes --markup yes --output-xhtml yes --quiet yes --quote-ampersand yes --quote-marks yes \
			| egrep -i '.*href=.*Power Gadget.*for macOS' \
			| sed -e 's#.* href="##g ; s#" .*##g' -e 's#^#https://software.intel.com#g')

	URL=$(curl -sfLS "$URL1" | tr '"' '\012' | egrep -i '^http.*\.dmg$' | head -1)

	LATEST_VERSION=$(curl -sfLS "$HOMEPAGE" \
		| tidy --tidy-mark no --char-encoding utf8 --wrap 0 --show-errors 0 --indent no --input-xml no --output-xml no \
			--quote-nbsp no --show-warnings no --uppercase-attributes no --uppercase-tags no --clean yes --force-output yes \
			--join-classes yes --join-styles yes --markup yes --output-xhtml yes --quiet yes --quote-ampersand yes --quote-marks yes \
		| egrep -i '.*href=.*Power Gadget.*for macOS' \
		| sed -e 's#</a>.*##g' -e 's#.*>##g' \
		| tr -dc '[0-9]\.')


else
		# Quoting “Patrick Konsor (Intel) said on Jul 25,2018” from $HOMEPAGE:
		# 	v3.5.3 removes support for macOS pre-10.13 due to stability concerns for a limited number of users.
		# 	If you would like to install on macOS 10.12 or earlier, you can try v3.5.2: https://software.intel.com/file/641033/download
		# https://software.intel.com/sites/default/files/managed/6c/0b/Intel%C2%AE%20Power%20Gadget.dmg

		# this is for 10.12 and earlier (although I think "earlier" is capped, at 10.7 maybe? Not sure)
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

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "URL: $URL\n\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

cat <<EOINPUT

*** NOTE: This .pkg can take an absurdly long time to install. This is is “normal”. Do not panic.

EOINPUT

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


# 2019-06-30 - this seems to be the way to get the actual URL now, although the way above still works, so I'm just keeping it as reference in case this ever breaks

HOMEPAGE="https://software.intel.com/en-us/articles/intel-power-gadget"

DOWNLOAD_PAGE=$(curl -sfLS "$HOMEPAGE" \
| tr '\r' '\n' \
| sed 's#<p>#\
<p>#g; s#</p>#</p>\
#g' \
| egrep -i 'href=".*Power Gadget .* for MacOS' \
| sed 's#.* href="/file/#https://software.intel.com/file/#g ; s#" .*##g')

URL=$(curl -sfLS "$DOWNLOAD_PAGE" \
| tr '\r' '\n' \
| sed 's#<a href#\
<a href#g ; s#</a>#</a>\
#g' \
| egrep -i 'https://software.intel.com/.*\.dmg' \
| head -1 \
| sed 's#.*https://#https://#g ; s#\.dmg.*#.dmg#g')

# Then you can use "$URL" to download the DMG
