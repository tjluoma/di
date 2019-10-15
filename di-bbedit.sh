#!/usr/bin/env zsh -f
# Purpose: Download or install/update the latest version of BBEdit
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-10-15

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/BBEdit.app'

SUMMARY='BBEdit is the leading professional HTML and text editor for macOS. It doesn’t suck.®'

HOMEPAGE="https://www.barebones.com/products/bbedit/"

DOWNLOAD_PAGE="https://www.barebones.com/support/bbedit/updates.html"

OS_VER=$(sw_vers -productVersion)

autoload is-at-least

################################################################################################################################################

while
do

	is-at-least "10.14.2" "$OS_VER" \
		&& URL='check' \
		&& break

	is-at-least '10.12.6' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_12.6.7.dmg' \
		&& SHA256_EXPECTED='d0647c864268b187343bd95bfcf490d6a2388579b1f8fce64a289c65341b1144' \
		&& LATEST_VERSION='12.6.7' \
		&& LATEST_BUILD='412120' \
		&& break

	is-at-least '10.11.6' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_12.1.6.dmg' \
		&& SHA256_EXPECTED='23b9fc6ef5c03cbcab041566503c556d5baf56b2ec18f551e6f0e9e6b48dc690' \
		&& LATEST_VERSION='12.1.6' \
		&& LATEST_BUILD='410110' \
		&& break

	is-at-least '10.9.5' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_11.6.8.dmg' \
		&& SHA256_EXPECTED='aa4a9f8ed12206dbf1d9e61c213be02789b87f963d8171743a3a057bfd1ede2a' \
		&& LATEST_VERSION='11.6.8' \
		&& LATEST_BUILD='397082' \
		&& break

	is-at-least '10.8.5' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_11.1.4.dmg' \
		&& SHA256_EXPECTED='9e14bcafaa2f1e9900a9826e2d51c194e530641b6fd5f55334444531736f68df' \
		&& LATEST_VERSION='11.1.4' \
		&& LATEST_BUILD='3780' \
		&& break

	is-at-least '10.6.8' "$OS_VER" \
		&& URL='http://pine.barebones.com/files/BBEdit_10.5.13.dmg' \
		&& SHA256_EXPECTED='2de7baf01ba12650e158e86c65bea72103eca840ab2de45121e3460d09a58ebd' \
		&& LATEST_VERSION='10.5.13' \
		&& LATEST_BUILD='3396' \
		&& break

	echo "$NAME: Sorry, I do not know what to do for Mac OS X version $OS_VER."

	exit 1

done

################################################################################################################################################

if [[ "$URL" == "check" ]]
then

	XML_FEED='https://versioncheck.barebones.com/BBEdit.xml'

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
	RELEASE_NOTES_URL="https://www.barebones.com/support/bbedit/notes-$LATEST_VERSION.html"

	FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

else
		# don't try to fetch release notes for old versions
	RELEASE_NOTES_URL=''

	FILENAME="$HOME/Downloads/$URL:t"
fi

################################################################################################################################################


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

else

	FIRST_INSTALL='yes'
fi

################################################################################################################################################

if [[ "$RELEASE_NOTES_URL" != "" ]]
then

	RELEASE_NOTES_FILE="$FILENAME:r.txt"

	if [[ -s "$RELEASE_NOTES_FILE" ]]
	then
			# if the file already exists, just show the contents

		cat "$RELEASE_NOTES_FILE"

	else
			# if the file does not exist, create it

		echo "$NAME: Fetching release notes..."

		(curl -sfL "http://heckyesmarkdown.com/go/?u=$RELEASE_NOTES_URL&read=1" \
		&& echo "\nSource: <$RELEASE_NOTES_URL>") | sed G | uniq | tee "$RELEASE_NOTES_FILE"

	fi

fi
################################################################################################################################################

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

################################################################################################################################################

if [[ "$SHA256_EXPECTED" != "" ]]
then

	SHA256_FILE="$FILENAME:r.sha256.txt"

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

################################################################################################################################################

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

################################################################################################################################################

if [[ -e "$INSTALL_TO" ]]
then
		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to Trash. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi
fi

################################################################################################################################################

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

################################################################################################################################################


exit 0
#EOF
