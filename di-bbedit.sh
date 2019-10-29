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

	# This is where the app will be installed or updated.
INSTALL_TO='/Applications/BBEdit.app'

	# Not current in use, but useful reference info
SUMMARY='BBEdit is the leading professional HTML and text editor for macOS. It doesn’t suck.®'
HOMEPAGE="https://www.barebones.com/products/bbedit/"
DOWNLOAD_PAGE="https://www.barebones.com/support/bbedit/updates.html"

	# This is the current version of macOS that this computer is running
OS_VER=$(sw_vers -productVersion)

	# a zsh-specific function for comparing numbers, including version numbers
autoload is-at-least

################################################################################################################################################

while
do

		## The first one of these to match will break the loop. We start with the newest version and work back.

		# for Mojave (10.14.2) and newer, look for the most recent version of BBEdit
	is-at-least "10.14.2" "$OS_VER" \
		&& URL='check' \
		&& break

		# for Sierra (10.12.6) or later, use BBEdit 12.6.7
	is-at-least '10.12.6' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_12.6.7.dmg' \
		&& SHA256_EXPECTED='d0647c864268b187343bd95bfcf490d6a2388579b1f8fce64a289c65341b1144' \
		&& LATEST_VERSION='12.6.7' \
		&& LATEST_BUILD='412120' \
		&& break

		# for El Capitan (10.11.6) or later, use BBEdit 12.1.6
	is-at-least '10.11.6' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_12.1.6.dmg' \
		&& SHA256_EXPECTED='23b9fc6ef5c03cbcab041566503c556d5baf56b2ec18f551e6f0e9e6b48dc690' \
		&& LATEST_VERSION='12.1.6' \
		&& LATEST_BUILD='410110' \
		&& break

		# for Mavericks (10.9.5) or later, use BBEdit 11.6.8
	is-at-least '10.9.5' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_11.6.8.dmg' \
		&& SHA256_EXPECTED='aa4a9f8ed12206dbf1d9e61c213be02789b87f963d8171743a3a057bfd1ede2a' \
		&& LATEST_VERSION='11.6.8' \
		&& LATEST_BUILD='397082' \
		&& break

		# for Mountain Lion (10.8.5) or later, use BBEdit 11.1.4
	is-at-least '10.8.5' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_11.1.4.dmg' \
		&& SHA256_EXPECTED='9e14bcafaa2f1e9900a9826e2d51c194e530641b6fd5f55334444531736f68df' \
		&& LATEST_VERSION='11.1.4' \
		&& LATEST_BUILD='3780' \
		&& break

		# for Snow Leopard (10.6.8) or later, use BBEdit 10.5.13
	is-at-least '10.6.8' "$OS_VER" \
		&& URL='https://s3.amazonaws.com/BBSW-download/BBEdit_10.5.13.dmg' \
		&& SHA256_EXPECTED='2de7baf01ba12650e158e86c65bea72103eca840ab2de45121e3460d09a58ebd' \
		&& LATEST_VERSION='10.5.13' \
		&& LATEST_BUILD='3396' \
		&& break

		# if you get here, you're probably Stephen Hackett or John Moltz. Sorry, I don't know
		# which versions of BBEdit go with older versions of Mac OS X
	echo "$NAME: Sorry, I do not know what to do for Mac OS X version $OS_VER."

	exit 1

done

################################################################################################################################################

if [[ "$URL" == "check" ]]
then

	## if we get here, we need to check for the latest version of BBEdit

		## this is the feed wherein the latest information is made available from Barebones
	XML_FEED='https://versioncheck.barebones.com/BBEdit.xml'

		## this is where we process that feed. There may be a better way of doing this,
		## and I'm open to suggestions. But this works, even on a Mac without any special tools installed.
	INFO=($(curl -sfL "$XML_FEED" \
			| egrep -A1 '<key>(SUFeedEntryShortVersionString|SUFeedEntryVersion|SUFeedEntryDownloadChecksum|SUFeedEntryDownloadURL)</key>' \
			| tail -11 \
			| tr -s '\t|\012' ' ' \
			| perl -p -e 's/^ // ; s/ -- /\n/ ; s/ -- /\n/  ; s/ -- /\n/ ' \
			| sed 's#<string>##g ; s#<\/string>##g ; s#<key>##g ; s#<\/key>##g' \
			| sort))

	## ok, so with the 'sort' this guarantees that the items will always be in this order:
	#
	#	SUFeedEntryDownloadChecksum
	#	SUFeedEntryDownloadURL
	#	SUFeedEntryShortVersionString
	#	SUFeedEntryVersion

	SHA256_EXPECTED="$INFO[2]"
	URL="$INFO[4]"
	LATEST_VERSION="$INFO[6]"
	LATEST_BUILD="$INFO[8]"

		## As long as Barebones keeps using this URL format, we don't need to calculate it each time
	RELEASE_NOTES_URL="https://www.barebones.com/support/bbedit/notes-$LATEST_VERSION.html"

		## this is where the file will be downloaded and what it will be named
	FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

else

	## if we get here, we are using a pre-defined version of BBEdit for our version of macOS/Mac OS X

		# don't try to fetch release notes for old versions
	RELEASE_NOTES_URL=''

	FILENAME="$HOME/Downloads/$URL:t"
fi

################################################################################################################################################

	## This is where we check the installed version -- if there is one -- against the most current information
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

fi

################################################################################################################################################

if [[ "$RELEASE_NOTES_URL" != "" ]]
then

		## if we have a release notes URL, then we want to save the information therein to a file

	RELEASE_NOTES_FILE="$FILENAME:r.txt"

	if [[ -s "$RELEASE_NOTES_FILE" ]]
	then
			# if the file already exists, just show the contents
		cat "$RELEASE_NOTES_FILE"

	else

			# Barebones' release notes are good enough that I'll go to extra lengths to get them

		if (( $+commands[wget] ))
		then

			if (( $+commands[html2text.py] ))
			then
				TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.html"

				wget --quiet --convert-links --output-document="$TEMPFILE" "$RELEASE_NOTES_URL"

				sed '1,/<p class="title">/d; /<p><em>fin<\/em><\/p>/,$d' "$TEMPFILE" | html2text.py > "$RELEASE_NOTES_FILE"

			else

				TEMPFILE="$FILENAME:r.html"

				wget --quiet --convert-links --output-document="$TEMPFILE" "$RELEASE_NOTES_URL"

			fi # if html2text.py

		fi # if wget

	fi # if release notes file

fi # if release notes URL

################################################################################################################################################

## Here is where the download happens and is verified

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

################################################################################################################################################

## The XML_FEED includes a shasum for the latest version, so we should use that to check that we got what we expected
## For older versions of BBEdit, I downloaded them from Barebones and checked them myself, and then added them.

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
##
## 	Once the DMG is verified, we mount it
##

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
##
##	Once the DMG is mounted, we should move the existing version of BBEdit out of the way, if it exists.
##

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
##
##	This is where we copy from the DMG to the expected destination
##

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

################################################################################################################################################
##
## if we made it this far, the installation went OK, so let's unmount the DMG
##

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

################################################################################################################################################


exit 0
#EOF
