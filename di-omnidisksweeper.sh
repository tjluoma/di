#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of OmniDiskSweeper
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-14

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniDiskSweeper.app'

HOMEPAGE="https://www.omnigroup.com/more"

DOWNLOAD_PAGE="https://www.omnigroup.com/more"

SUMMARY="OmniDiskSweeper is really great at what it does: showing you the files on your drive, in descending order by size, and letting you decide what to do with them. Delete away, but exercise caution: OmniDiskSweeper does not perform any safety checks before deleting files!"

XML_FEED='http://update.omnigroup.com/appcast/com.omnigroup.OmniDiskSweeper/'

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| fgrep '<omniappcast:releaseNotesLink>' \
		| sed 's#.*<omniappcast:releaseNotesLink>##g ; s#<\/omniappcast:releaseNotesLink>##g' \
		| head -1)

	# No other version information available in feed
INFO=($(curl -sfL "$XML_FEED" \
	| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
	| egrep '<omniappcast:marketingVersion>|<enclosure .*\.dmg' \
	| head -2 \
	| sed 's#<omniappcast:marketingVersion>##g; s#<\/omniappcast:marketingVersion>##g ; s#.*https#https#g ; s#\.dmg.*#.dmg#g' \
	| sort))

LATEST_VERSION="$INFO[1]"

	# https://www.omnigroup.com/download/latest/OmniDiskSweeper
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

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f1,2)

case "$OS_VER" in
	'10.13')
		URL='http://downloads.omnigroup.com/software/MacOSX/10.13/OmniDiskSweeper-1.11(n).dmg'
		LATEST_VERSION="1.11"
		RELEASE_NOTES_URL=''
	;;
	'10.12')
		URL='http://downloads.omnigroup.com/software/MacOSX/10.12/OmniDiskSweeper-1.10.dmg'
		LATEST_VERSION="1.10"
		RELEASE_NOTES_URL=''
	;;

	'10.8'|'10.9'|'10.10'|'10.11')
		URL='http://downloads.omnigroup.com/software/MacOSX/10.8/OmniDiskSweeper-1.9.dmg'
		LATEST_VERSION="1.9"
		RELEASE_NOTES_URL=''
	;;

	'10.6'|'10.7')
		URL='http://downloads.omnigroup.com/software/MacOSX/10.6/OmniDiskSweeper-1.8.dmg'
		LATEST_VERSION="1.8"
		RELEASE_NOTES_URL=''
	;;

	'10.5'|'10.4')
		URL='http://downloads.omnigroup.com/software/MacOSX/10.4/OmniDiskSweeper-1.7.2.dmg'
		LATEST_VERSION="1.7.2"
		RELEASE_NOTES_URL=''
	;;

esac

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

if (( $+commands[lynx] ))
then

	if [[ "$RELEASE_NOTES_URL" != "" ]]
	then

		( echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<article>/d; /<\/article>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

	fi
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Accepting EULA and mounting $FILENAME: (sorry if this opens a Finder window)"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
