#!/bin/zsh
# Purpose: download and install HandBrake nightly
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-08-18


## HandBrake has a Sparkle feed, but it seems vastly out of date 
# XML_FEED='https://handbrake.fr/appcast_unstable.x86_64.xml'


NAME="$0:t:r"

die ()
{
	echo "$NAME: $@"
	exit 1
}

INSTALL_TO="/Applications/HandBrake.app"


INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null | awk '{print $1}' || echo '1.0.0'`
 
UA='curl/7.21.7 (x86_64-apple-darwin10.8.0) libcurl/7.21.7 OpenSSL/1.0.0d zlib/1.2.5 libidn/1.22'


if ((! $+commands[lynx] ))
then
	# note: if lynx is a function or alias, it will come back not found

	echo "$NAME: lynx is required but not found in $PATH"
	exit 1
fi

URL=`lynx -listonly -dump -nomargins -nonumbers 'http://handbrake.fr/nightly.php' | fgrep -i .dmg | fgrep -iv "CLI"`

	# if there URL is empty, give up
[[ "$URL" == "" ]] && die "URL is empty"

LATEST_VERSION=`echo "$URL:t:r" | sed 's#HandBrake-##g; s#-osx##g'`

##### This does not work for some reason 
## function version { echo "$@" | awk -F. '{ printf("28%03d%03d%03d\n", $1,$2,$3,$4); }'; }
## if [ $(version ${LATEST_VERSION}) -le $(version ${INSTALLED_VERSION}) ]

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
		# No Update Needed
	echo "$NAME: Up To Date (Installed: $INSTALLED_VERSION and Latest: $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Out of Date: $INSTALLED_VERSION vs $LATEST_VERSION"

cd '/Volumes/Data/Websites/iusethis.luo.ma/handbrake/nightly/' 2>/dev/null \
	|| cd '/Volumes/Drobo2TB/BitTorrent Sync/iusethis.luo.ma/handbrake/nightly/' 2>/dev/null \
	|| cd "$HOME/BitTorrent Sync/iusethis.luo.ma/handbrake/nightly/" 2>/dev/null \
	|| cd "$HOME/Downloads/" \
	|| cd "$HOME/Desktop/" \
	|| cd "$HOME/"

FILENAME="$HOME/Downloads/$URL:t"

echo "$NAME: Downloading $URL to $FILENAME"

curl -A "$UA" --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')


if [ -e "$INSTALL_TO" ]
then

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/HandBrake.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -v "$MNTPNT/HandBrake.app" "$INSTALL_TO"

if (( $+commands[unmount.sh] ))
then

	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"	

fi

exit 0

#
#EOF
