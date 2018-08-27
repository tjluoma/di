#!/bin/zsh -f
# Purpose: Download and install the latest version of BBEdit determined by OS version
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

NAME="$0:t:r"

INSTALL_TO='/Applications/BBEdit.app'

SUMMARY='BBEdit is the leading professional HTML and text editor for macOS. It doesn’t suck.®'

HOMEPAGE="https://www.barebones.com/products/bbedit/"

DOWNLOAD_PAGE="https://www.barebones.com/support/bbedit/updates.html"

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

ARGS_GIVEN='no'

OS_VER=$(sw_vers -productVersion)

OS_VER_SHORT=$(sw_vers -productVersion | cut -d '.' -f 2)

autoload is-at-least

function use_v12 {

	USE12='yes'

		## 2018-07-17 Found new URL via find_appcast
		#  XML_FEED='https://versioncheck.barebones.com/BBEdit.cgi'
	XML_FEED='https://versioncheck.barebones.com/BBEdit.xml'


	INFO=($(curl -sfL "$XML_FEED" \
			| egrep -A1 '<key>(SUFeedEntryShortVersionString|SUFeedEntryDownloadChecksum|SUFeedEntryDownloadURL)</key>' \
			| tail -8 \
			| tr -s '\t|\012' ' ' \
			| perl -p -e 's/^ // ; s/ -- /\n/ ; s/ -- /\n/ ' \
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

	#echo "
	#SHA256_EXPECTED: $SHA256_EXPECTED
	#URL: $URL
	#LATEST_VERSION: $LATEST_VERSION
	#"

}

function use_v11 {

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

		is-at-least "10.6.8"  "$OS_VER" 	&& use_v10

		is-at-least "10.8.5"  "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_11.1.4.dmg" 	&& LATEST_VERSION="11.1.4"

		is-at-least "10.9.5"  "$OS_VER" 	&& URL="https://s3.amazonaws.com/BBSW-download/BBEdit_11.6.8.dmg" 	&& LATEST_VERSION="11.6.8"

		is-at-least "10.11.6" "$OS_VER"	&& use_v12

	fi
fi

## I don't actually have any Macs running a version of Mac OS older than 10.11.6, so it's a hard thing to test

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

RELEASE_NOTES_FILE="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.txt"

SHA256_FILE="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.sha256"

if [[ "$USE12" = "yes" ]]
then
	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL="https://www.barebones.com/support/bbedit/notes-$LATEST_VERSION.html"

		echo "$NAME: Release notes for $INSTALL_TO:t:r version $LATEST_VERSION:\n\nAdditions"

		lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" \
		| sed '1,/^Additions$/d; /Newsflash(es)/,$d'

		echo "\nSource: <$RELEASE_NOTES_URL>"
	fi
fi


echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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
	echo "$SHA256_EXPECTED $FILENAME" >| "$SHA256_FILE"

	echo	"$NAME: Verifying sha256 checksum of '$FILENAME':"

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

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Successfully installed $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi

diskutil eject "$MNTPNT"

if ((! $+commands[bbedit] ))
then

	BBEDIT="$INSTALL_TO/Contents/Helpers/bbedit_tool"

	if [[ -e "${BBEDIT}" ]]
	then
		if [[ -w /usr/local/bin ]]
		then
			ln -s "${BBEDIT}" /usr/local/bin/bbedit && \
			echo "$NAME: Linked ${BBEDIT} to /usr/local/bin/bbedit"
		else
			echo "$NAME: cannot link ${BBEDIT} to /usr/local/bin because it is not writable."
		fi
	else
		echo "$NAME: Did not find 'bbedit_tool' at ${BBEDIT}"
	fi
fi

for i in bbdiff bbfind bbresults
do
	if ((! $+commands[$i] ))
	then

		BBCMD="$INSTALL_TO/Contents/Helpers/$i"

		if [[ -e "${BBCMD}" ]]
		then
			if [[ -w /usr/local/bin ]]
			then
				ln -s "${BBCMD}" /usr/local/bin/${i} && \
				echo "$NAME: Linked '${BBCMD}' to '/usr/local/bin/$i'."
			else
				echo "$NAME: cannot link '${BBCMD}' to '/usr/local/bin/$i' because '/usr/local/bin/' is not writable."
			fi
		else
			echo "$NAME: Did not find '$i' at '${BBCMD}'"
		fi
	fi
done

exit 0
#EOF
