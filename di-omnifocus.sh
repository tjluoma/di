#!/usr/bin/env zsh -f
# Purpose: Download and install the latest OmniFocus 2 or 3 (depending on which is installed)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-21

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/OmniFocus.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/OmniFocus.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

HOMEPAGE="https://www.omnigroup.com/omnifocus"

DOWNLOAD_PAGE="https://www.omnigroup.com/download/latest/omnifocus/"

SUMMARY="Live a productive, contextual life with OmniFocus. Keep work and play separated with contexts, perspectives, and Focus. Ignore the irrelevant, focus on what you can do now, and accomplish more. And do it all much faster than before."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

function use_v2 {
	XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniFocus2/"
	ITUNES_URL="apps.apple.com/us/app/omnifocus-2/id867299399"
	ASTERISK='Note: version 3 is now available from: <https://www.omnigroup.com/omnifocus>'
}

function use_v3 {

	XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniFocus3/"
	ITUNES_URL="apps.apple.com/us/app/omnifocus-3/id1346203938"
	ASTERISK=''
}

if [[ -e "$INSTALL_TO" ]]
then
		# if v2 is installed, check that. Otherwise, use v3
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "2" ]]
	then
		use_v2
	else
		use_v3
	fi
else
	if [ "$1" = "--use2" -o "$1" = "-2" ]
	then
		use_v2
	else
		use_v3
	fi
fi

	## Note: Downloads are available in tbz2 and dmg but dmg has EULA so I use tbz2
INFO=($(curl -sfL "$XML_FEED" \
		| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0  \
		| egrep '<omniappcast:buildVersion>|<omniappcast:releaseNotesLink>|<omniappcast:marketingVersion>|url=.*\.tbz2' \
		| head -4 \
		| sort \
		| sed \
			-e 's#.*url="##g ; s#".*##g' \
			-e 's#<omniappcast:marketingVersion>##g ; s#<\/omniappcast:marketingVersion>##g' \
			-e 's#<omniappcast:buildVersion>##g ; s#<\/omniappcast:buildVersion>##g' \
			-e 's#<omniappcast:releaseNotesLink>##g ; s#<\/omniappcast:releaseNotesLink>##g'))

URL="$INFO[1]"
LATEST_BUILD="$INFO[2]"
LATEST_VERSION="$INFO[3]"
RELEASE_NOTES_URL="$INFO[4]"

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

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
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD) ${ASTERISK}"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.tbz2"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r $LATEST_VERSION/$LATEST_BUILD:\n" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<article>/d; /<\/article>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TRASH}/${NAME}-XXXXXXXX")

echo "$NAME: Installing $FILENAME to $UNZIP_TO"

tar -x -C "$UNZIP_TO" -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" != "0" ]
then
	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $TRASH/"
		exit 1
	fi
fi

	# move the app from the temp folder to the regular installation dir
mv -vf "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then

	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0

#EOF
