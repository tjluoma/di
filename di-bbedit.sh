#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of BBEdit determined by OS version
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/BBEdit.app'

SUMMARY='BBEdit is the leading professional HTML and text editor for macOS. It doesn’t suck.®'

HOMEPAGE="https://www.barebones.com/products/bbedit/"

DOWNLOAD_PAGE="https://www.barebones.com/support/bbedit/updates.html"

ARGS_GIVEN='no'

OS_VER=$(sw_vers -productVersion)

OS_VER_SHORT=$(sw_vers -productVersion | cut -d '.' -f 2)

autoload is-at-least

function use_v12 {

	USE12='yes'

	PREFERS_BETAS_FILE="$HOME/.config/di/prefers/BBEdit-prefer-betas.txt"

	if [[ -e "$PREFERS_BETAS_FILE" ]]
	then
		XML_FEED='https://versioncheck.barebones.com/BBEdit-410.xml'

		NAME="$NAME (beta releases)"

	else

		## 2018-07-17 Found new URL via find_appcast
		#  XML_FEED='https://versioncheck.barebones.com/BBEdit.cgi'
		XML_FEED='https://versioncheck.barebones.com/BBEdit.xml'

	fi

	INFO=($(curl -sfL "$XML_FEED" \
			| egrep -A1 '<key>(SUFeedEntryShortVersionString|SUFeedEntryVersion|SUFeedEntryDownloadChecksum|SUFeedEntryDownloadURL)</key>' \
			| tail -11 \
			| tr -s '\t|\012' ' ' \
			| perl -p -e 's/^ // ; s/ -- /\n/ ; s/ -- /\n/  ; s/ -- /\n/ ' \
			| sed 's#<string>##g ; s#<\/string>##g ; s#<key>##g ; s#<\/key>##g' \
			| sort))

	## ok, so with the 'sort' this guarantees that the items will always be in this order:
	#
	#	SUFeedEntryDownloadChecksum ef8795bee09830944b4018377280888c28cf26a0591c2994c50cd2837fef9f67
	#	SUFeedEntryDownloadURL https://s3.amazonaws.com/BBSW-download/BBEdit_12.1.5.dmg
	#	SUFeedEntryShortVersionString 12.1.5

	SHA256_EXPECTED="$INFO[2]"
	URL="$INFO[4]"
	LATEST_VERSION="$INFO[6]"
	LATEST_BUILD="$INFO[8]"

	#echo "
	#SHA256_EXPECTED: $SHA256_EXPECTED
	#URL: $URL
	#LATEST_VERSION: $LATEST_VERSION
	#"

}

function use_v11 {

	# BBEdit 11.1.4
	# This update is provided for customers running OS X 10.8.5.
	# If you are using OS X 10.9.5 or later, BBEdit 11.6.2 is recommended. You must have a BBEdit 11 serial number to use this version.
	# This version of BBEdit is not compatible with macOS “High Sierra”. If you are running macOS 10.13 or later, please use BBEdit 12.

	# BBEdit 11.6.8
	# Important: BBEdit 11 requires Mac OS X 10.9.5 or later, and will not run on any earlier version of Mac OS X.
	# This version of BBEdit is not compatible with macOS “High Sierra and later”. If you are running macOS 10.13 or later, please use BBEdit 12.

	if [ "$OS_VER_SHORT" -ge "13" ]
	then
		echo "$NAME: Cannot use BBEdit v11 with macOS High Sierra (10.13) or later. Must use v12."

		use_v12
	else

		is-at-least "10.8.5"  "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_11.1.4.dmg" 	&& LATEST_VERSION="11.1.4"

		is-at-least "10.9.5"  "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_11.6.8.dmg" 	&& LATEST_VERSION="11.6.8"
	fi
}

function use_v10 {

		## I do not know what the 'maximum' version of macOS is for version 10 of BBEdit

	if [ "$OS_VER_SHORT" -ge "13" ]
	then
		echo "$NAME: Cannot use BBEdit v10 with macOS High Sierra (10.13) or later. Must use v12."

		use_v12
	else
		is-at-least "10.6.8" "$OS_VER" \
		&& URL="http://pine.barebones.com/files/BBEdit_10.5.13.dmg" \
		&& LATEST_VERSION="10.5.13"
	fi

}

case "$@" in
	--use12)
		use_v12
		ARGS_GIVEN='yes'
	;;

	--use11)
		use_v11
		ARGS_GIVEN='yes'
	;;

	--use10)
		use_v10
		ARGS_GIVEN='yes'
	;;

esac

if [ "$ARGS_GIVEN" = "no" ]
then

	if [ "$OS_VER_SHORT" -ge "13" ]
	then

		use_v12

	else

		is-at-least "10.6.8"   "$OS_VER" 	&& use_v10

		# There may be a better version to specify for macOS 10.7

		is-at-least "10.8.5"   "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_11.1.4.dmg" 	&& LATEST_VERSION="11.1.4"

		is-at-least "10.9.5"   "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_11.6.8.dmg" 	&& LATEST_VERSION="11.6.8"

		is-at-least "10.11.6"  "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_12.1.6.dmg" 	&& LATEST_VERSION="12.1.6"

		is-at-least "10.12.6"  "$OS_VER"	&& use_v12

	fi
fi

	# If either of these are blank, we cannot continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	if [[ "$LATEST_BUILD" == "" ]]
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
	else

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

	fi

fi

## Release Notes: Well, if you wanted to, you could do something like this:
##
# curl -sfL https://versioncheck.barebones.com/BBEdit.xml \
# | sed '1,/<string>397082<\/string>/d' \
# | sed '/<\/data>/,$d' \
# | sed '1,/<data>/d' \
# | base64 --decode \
# | unrtf \
# | tr -s '"' '"' \
# | lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin -listonly \
# | head -1
##
## which would get you something like:
# https://www.barebones.com/support/bbedit/notes-12.1.5.html
## or, if you remove the '-listonly' part, you'll get this:
# BBEdit 12.1.5 is a focused maintenance update to address issues reported in BBEdit 12.0 through 12.1.4. Detailed change notes are available hyperlink.
##
## But rather than go through all that, why not just guess that the URL will be:
## "https://www.barebones.com/support/bbedit/notes-$LATEST_VERSION.html"
## ?
## So that's what I'm doing instead.

if [[ "$LATEST_BUILD" == "" ]]
then
	FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"
else
	FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.dmg"
fi

	RELEASE_NOTES_FILE="$FILENAME:r.txt"

	SHA256_FILE="$FILENAME:r.sha256.txt"

if [[ "$USE12" = "yes" ]]
then

	RELEASE_NOTES_URL="https://www.barebones.com/support/bbedit/notes-$LATEST_VERSION.html"

	if [[ -s "$RELEASE_NOTES_FILE" ]]
	then
			# if the file already exists, just show the contents

		cat "$RELEASE_NOTES_FILE"

	else
			# if the file does not exist, create it

		(curl -sfL "http://fuckyeahmarkdown.com/go/?u=$RELEASE_NOTES_URL&read=1" \
		&& echo "\nSource: <$RELEASE_NOTES_URL>") | sed G | uniq | tee "$RELEASE_NOTES_FILE"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ "$SHA256_EXPECTED" != "" ]]
then
		# if we get here, we have something to compare against
		# put the expected value (which we got from the XML_FEED
		# into a text file with the full path of the filename of the file we just downloaded
		# and then we can check it with 'shasum --check'
		##
	echo "$SHA256_EXPECTED ?$FILENAME:t" >| "$SHA256_FILE"

	echo -n "$NAME: Verifying sha256 checksum of '$FILENAME': "

	cd "$FILENAME:h"

	shasum --check "$SHA256_FILE"

	SHASUM_EXIT="$?"

	if [ "$SHASUM_EXIT" = "0" ]
	then
		echo "$NAME: '$FILENAME' matches the expected signature."

	else
		echo "$NAME: checksum failed (\$SHASUM_EXIT = $SHASUM_EXIT)"
		echo "$NAME: Moving '$FILENAME' and related files to the Trash, as they may be unsafe."

		[[ -e "$FILENAME" ]] && mv -vf "$FILENAME" "$HOME/.Trash/"

		[[ -e "$RELEASE_NOTES_FILE" ]] && mv -vf "$RELEASE_NOTES_FILE" "$HOME/.Trash/"

		[[ -e "$SHA256_FILE" ]] && mv -vf "$SHA256_FILE" "$HOME/.Trash/"

		exit 1
	fi
fi

if [ -e "$INSTALL_TO" ]
then

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Mounting '$FILENAME':"

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

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO':"

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Successfully installed $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi

echo -n "$NAME: Ejecting '$MNTPNT': "

diskutil eject "$MNTPNT"

if (( $+commands[install-bbedit-cli-tools-and-manpages.sh] ))
then
		# This is a separate script I wrote just to make sure that the CLI tools
		# and man pages are installed correctly, but I want to be able to run it
		# separate from this script, so it's not part of it.

	install-bbedit-cli-tools-and-manpages.sh

fi

exit 0
#EOF
