#!/usr/bin/env zsh -f
# Purpose:	Download and install/update the latest version of Zoom
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2022-03-24
# Verified:	2025-02-15

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/zoom.us.app'

RELEASE_NOTES_URL='https://support.zoom.us/hc/en-us/articles/201361963-Release-notes-for-macOS'

ARCH=$(sysctl kern.version | awk -F'_' '/RELEASE/{print $2}')

if [[ "$ARCH" == "ARM64" ]]
then

	PKG_URL='https://zoom.us/client/latest/Zoom.pkg?archType=arm64'

elif [[ "$ARCH" == "X86" ]]
then

	PKG_URL='https://zoom.us/client/latest/Zoom.pkg'

else

	echo "$NAME: 'sysctl kern.version' returned unknown arch: '$ARCH'" >>/dev/stderr
	exit 2

fi

URL=$(curl -sfLS --head "$PKG_URL" | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

LATEST_VERSION=$(echo "${URL}" | awk -F'/' '/http/{print $5}')

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi


echo "
$URL
$LATEST_VERSION
"


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

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/Zoom-${LATEST_VERSION}.$ARCH:l.pkg"

if (( $+commands[lynx] ))
then

	(curl -A Safari -sfLS "$RELEASE_NOTES_URL" \
		| sed '1,/<h2>Current Release<\/h2>/d; /<h2>Previous Releases<\/h2>/,$d' \
		| fgrep -v '<hr class="style-two" />' \
		| lynx -dump -nomargins -width='1000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: $RELEASE_NOTES_URL\nURL: $URL" ) \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

########

echo "$NAME: Preparing to install $FILENAME"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME"

else

	if [ "$EUID" = "0" ]
	then

		/usr/sbin/installer -pkg "$FILENAME" -target / -lang en

	else
			# Try sudo but if it fails, open pkg in Finder
		sudo /usr/sbin/installer -pkg "$FILENAME" -dumplog -target / -lang en \
		|| open -R "$FILENAME"

	fi
fi



exit 0
#EOF
