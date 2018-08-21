#!/bin/zsh -f
# Purpose: Download and install Mailplane.app v3 or 4, depending on which is installed (if any)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2018-08-20

NAME="$0:t:r"

V3_INSTALL_TO='/Applications/Mailplane 3.app'
V4_INSTALL_TO='/Applications/Mailplane.app'

function use_v3 {

	INSTALL_TO="/Applications/Mailplane 3.app"

	URL=$(curl -sfL --head "http://update.mailplaneapp.com/mailplane_3.php" \
		| awk -F'\r|: ' '/^Location/{print $2}' \
		| tail -1)

	LATEST_VERSION=`echo "$URL:t:r" | sed 's#Mailplane_3_##g'`

	FILENAME="$HOME/Downloads/MailPlane-3-${LATEST_VERSION}.tbz"
}

function use_v4 {

	INSTALL_TO="/Applications/Mailplane.app"

	OS_VER=`sw_vers -productVersion`

	INSTALLED_BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '4000'`

	XML_FEED="https://update.mailplaneapp.com/appcast.php?appName=Mailplane%203&osVersion=${OS_VER}&appVersion=${INSTALLED_BUILD}&selectedLanguage=en"

	INFO=($(curl -sfL "$XML_FEED" \
			| tr -s ' ' '\012' \
			| egrep 'sparkle:shortVersionString=|sparkle:version=|url=' \
			| head -3 \
			| sort \
			| awk -F'"' '/^/{print $2}' ))

		# "Sparkle" will always come before "url" because of "sort"
		# We aren't using INFO[1] because we really just need the build
	LATEST_VERSION="$INFO[2]"
	URL="$INFO[3]"

		# n.b. 'http://update.mailplaneapp.com/mailplane_4.php' does redirect to the latest v4 version
		# (after a few redirects along the way). Here's the current version
		# Location: https://update.mailplaneapp.com/builds/Mailplane_4_4516.tbz

	FILENAME="$HOME/Downloads/MailPlane-4-${LATEST_VERSION}.tbz"
}

	# if the user explicitly askes for version 3, use it, regardless of the above
if [ "$1" = "--use3" -o "$1" = "-3" ]
then
	use_v3
elif [ "$1" = "--use4" -o "$1" = "-4" ]
then
	use_v4
else
	if [ -e "$V3_INSTALL_TO" -a -e "$V4_INSTALL_TO" ]
	then
		echo "$NAME: Both versions 3 and 4 of Mailplane are installed. I will _only_ check for updates for version 4 in this situation."
		echo "	If you want to check for updates for version 3, add the argument '--use3' i.e. '$0:t --use3' "
		echo "	To avoid this message in the future, add the argument '--use4' i.e. '$0:t --use4' "

		use_v4

	elif [ ! -e "$V3_INSTALL_TO" -a -e "$V4_INSTALL_TO" ]
	then
			# version 3 is not installed but version 4 is
		use_v4
	elif [ -e "$V3_INSTALL_TO" -a ! -e "$V4_INSTALL_TO" ]
	then
			# version 3 is installed but version 4 is not
		use_v3
	else
			# neither v3 or v4 are installed
		use_v4
	fi
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

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

# FILENAME is defined above

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/MailPlane.$INSTALLED_VERSION.$INSTALLED_BUILD.app"
fi

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping $FILENAME to $UNZIP_TO"

tar -x -C "$UNZIP_TO" -j -f "$FILENAME"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

mv -vf "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful"
	exit 0
else
	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

exit 0
#
#EOF

