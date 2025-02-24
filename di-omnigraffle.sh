#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of OmniGraffle 6 or 7
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2016-05-10
# Verified:	2025-02-24

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniGraffle.app'

HOMEPAGE="https://www.omnigroup.com/omnigraffle"

DOWNLOAD_PAGE="https://www.omnigroup.com/download/latest/omnigraffle/"

SUMMARY="OmniGraffle is for creating precise, beautiful graphics: website wireframes, electrical systems, family trees and maps of software classes come to life in OmniGraffle 7. "

function use_v6 {
	XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniGraffle6"
	ASTERISK='(Note that version 7 is also available.)'
}

function use_v7 { XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniGraffle7" }

if [[ -e "$INSTALL_TO" ]]
then
		# if v6 is installed, check that. Otherwise, use v7
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "6" ]]
	then
		use_v6
	else
		use_v7
	fi
else
	if [ "$1" = "--use6" -o "$1" = "-6" ]
	then
		use_v6
	else
		use_v7
	fi
fi

LAUNCH='no'

## Note: Downloads are available in tbz2 and dmg, but dmg has EULA so I use tbz2

INFO=($(curl -sfL "$XML_FEED" \
		| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
		| egrep '<omniappcast:releaseNotesLink>|<omniappcast:marketingVersion>|url=.*\.tbz2' \
		| head -3 \
		| sort \
		| sed \
			-e 's#.*url="##g ; s#".*##g' \
			-e 's#<omniappcast:marketingVersion>##g ; s#<\/omniappcast:marketingVersion>##g' \
			-e 's#<omniappcast:releaseNotesLink>##g ; s#<\/omniappcast:releaseNotesLink>##g'))

URL="$INFO[1]"
LATEST_VERSION="$INFO[2]"
RELEASE_NOTES_URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$RELEASE_NOTES_URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	RELEASE_NOTES_URL: $RELEASE_NOTES_URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info"  CFBundleShortVersionString 2>/dev/null || echo '0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
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

FILENAME="$HOME/Downloads/OmniGraffle-$LATEST_VERSION.tbz2"

if (( $+commands[lynx] ))
then

	( lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL";
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unpacking '$FILENAME' to '$UNZIP_TO':"

tar -x -C "$UNZIP_TO" -f "$FILENAME"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: tar failed (\$EXIT = $EXIT)"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"
		exit 1
	fi
fi
	# Note name difference
mv -vf "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0

#EOF
