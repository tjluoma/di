#!/bin/zsh -f
# Purpose: Download and install the latest version of Lingon X
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-14

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Lingon X.app'

OLD_VERSION='yes'

SPARKLE_VERSION='sparkle:shortVersionString'

OS_VER=$(sw_vers -productVersion | cut -d '.' -f 1,2)

OS_VER_SHORT=$(sw_vers -productVersion | cut -d '.' -f 2)

if [[ -e "$INSTALL_TO" ]]
then

	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	case "$MAJOR_VERSION" in
		1)
			XML_FEED='https://www.peterborgapps.com/updates/lingonx-appcast.xml'
			SPARKLE_VERSION='sparkle:version'
		;;

		2)
			XML_FEED='https://www.peterborgapps.com/updates/lingonx2-appcast.xml'
		;;

		# FYI - Lingon 3 was only released in the Mac App Store: <https://itunes.apple.com/us/app/lingon-3/id450201424>

		4)
			XML_FEED='https://www.peterborgapps.com/updates/lingonx4-appcast.xml'
		;;

		5)
			XML_FEED='https://www.peterborgapps.com/updates/lingonx5-appcast.xml'
		;;

		*)
			XML_FEED='https://www.peterborgapps.com/updates/lingonx6-appcast.xml'
			OLD_VERSION='no'
		;;

	esac

else

	case "$OS_VER" in
		10.8|10.9)
				XML_FEED='https://www.peterborgapps.com/updates/lingonx-appcast.xml'
				SPARKLE_VERSION='sparkle:version'
		;;

		10.10)
				XML_FEED='https://www.peterborgapps.com/updates/lingonx2-appcast.xml'
		;;

		10.11)
				XML_FEED='https://www.peterborgapps.com/updates/lingonx4-appcast.xml'
		;;

		10.12)
				XML_FEED='https://www.peterborgapps.com/updates/lingonx5-appcast.xml'
		;;

		10.13|10.14)
			XML_FEED='https://www.peterborgapps.com/updates/lingonx6-appcast.xml'
			OLD_VERSION='no'

		;;

		*)
			echo "$NAME: Not sure if 'Lingon X' can run on this version of Mac OS: $OS_VER"
			exit 1
		;;

	esac

fi

HOMEPAGE="https://www.peterborgapps.com/lingon/"

DOWNLOAD_PAGE="https://www.peterborgapps.com/lingon/#otherversions"

SUMMARY="Lingon can start an app, a script or run a command automatically whenever you want it to. You can schedule it to run at a specific time, regularly or when something special happens."

INFO=($(curl -sfL "$XML_FEED" \
		| tr '\r' '\n' \
		| tr -s ' ' '\012' \
		| egrep "$SPARKLE_VERSION|url=" \
		| head -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

		# Lingon X v1 uses CFBundleShortVersionString even though the XML_FEED only shows 'sparkle:version='
	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"

		if [ "$OLD_VERSION" = "yes" -a "$OS_VER_SHORT" -ge "13" ]
		then
			echo "$NAME: 'Lingon X' version 6 is now available. See <https://www.peterborgapps.com/lingon/> for more details."
		fi

		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/LingonX-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	( curl -sfL "$RELEASE_NOTES_URL" \
	| tr '\r' '\n' \
	| perl -pe 's/<!\[CDATA\[/\n/g ; s/\]\]>/\n/g' \
	| fgrep -v '<description>Lingon X</description>' \
	| sed '1,/<description>/d; /<\/description>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
