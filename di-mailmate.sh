#!/bin/zsh -f
# Purpose: Download and install the latest version of MailMate
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-01

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/MailMate.app'
else
	INSTALL_TO='/Applications/MailMate.app'
fi

HOMEPAGE="https://freron.com"

DOWNLOAD_PAGE="https://freron.com/download/"

SUMMARY="MailMate is an IMAP email client for macOS featuring extensive keyboard control, Markdown integrated email composition, advanced search conditions and drill-down search links, equally advanced smart mailboxes, automatic signature handling, cryptographic encryption/signing (OpenPGP and S/MIME), tagging, multiple notification methods, alternative message viewer layouts including a widescreen layout, flexible integration with third party applications, and much more."

	# 2018-08-08 - This says that it's for betas, but I can't find a non-beta version at the moment
RELEASE_NOTES_URL='https://updates.mailmate-app.com/beta_release_notes'

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH='no'

	# if you want to install beta releases
	# create a file (empty, if you like) using this file name/path:
PREFERS_BETAS_FILE="$HOME/.config/di/prefers/mailmate-prefer-betas.txt"

if [[ -e "$PREFERS_BETAS_FILE" ]]
then
	XML_FEED='http://updates.mailmate-app.com/beta'
	NAME="$NAME (beta releases)"
else
		## This is for official, non-beta versions
	XML_FEED='http://updates.mailmate-app.com/'
fi

	# Very minimal feed. Uses same version # as CFBundleVersion
INFO=($(curl -sfL "$XML_FEED" | awk '{print $4" " $7}' | tr -d "'|;"))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read $INSTALL_TO/Contents/Info CFBundleVersion 2>/dev/null || echo '0'`

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

if (is-growl-running-and-unpaused.sh)
then

	growlnotify \
		--sticky \
		--appIcon "$INSTALL_TO:t:r" \
		--identifier "$NAME" \
		--message "Updating to $LATEST_VERSION" \
		--title "$NAME"
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.tbz"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_TXT="$FILENAME:r.txt"

	( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
		(curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<body>/d; /<\/ul>/,$d' \
		;echo '</ul>') \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$RELEASE_NOTES_TXT"
fi

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		pgrep -x -q MailMate \
		&& LAUNCH='yes' \
		&& osascript -e 'tell application "MailMate" to quit'

		mv "$INSTALL_TO" "$INSTALL_TO:h/.Trashes/$UID/MailMate.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"

tar -C "$INSTALL_TO:h" -j -x -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	if (is-growl-running-and-unpaused.sh)
	then

		growlnotify \
			--appIcon "$INSTALL_TO:t:r" \
			--identifier "$NAME" \
			--message "Update Complete! ($LATEST_VERSION)" \
			--title "$NAME"
	fi

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

if [[ -d "${INSTALL_TO}" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	DIRNAME="$FILENAME:h"
	EXT="$FILENAME:e"

		# rename the download to show full version info
	mv -vf "$FILENAME" "$DIRNAME/$INSTALL_TO:t:r-${INSTALLED_VERSION}_${INSTALLED_BUILD}.$EXT"

		# rename the release notes to show full version info
	mv -vf "$RELEASE_NOTES_TXT" "$DIRNAME/$INSTALL_TO:t:r-${INSTALLED_VERSION}_${INSTALLED_BUILD}.txt"

fi

exit 0
#EOF
