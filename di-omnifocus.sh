#!/usr/bin/env zsh -f
# Purpose: 	Download and install/update the latest version of OmniFocus 4
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2025-02-15
# Verified:	2025-02-15


if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniFocus.app'

HOMEPAGE="https://www.omnigroup.com/omnifocus"

DOWNLOAD_PAGE="https://www.omnigroup.com/download/latest/omnifocus/"

SUMMARY="Live a productive, contextual life with OmniFocus. Keep work and play separated with contexts, perspectives, and Focus. Ignore the irrelevant, focus on what you can do now, and accomplish more. And do it all much faster than before."

XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniFocus4/"

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

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.tbz2"

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

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

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
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"
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
