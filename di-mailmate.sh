#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of MailMate
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-01

NAME="$0:t:r"

INSTALL_TO='/Applications/MailMate.app'

HOMEPAGE="https://freron.com"

DOWNLOAD_PAGE="https://freron.com/download/"

SUMMARY="MailMate is an IMAP email client for macOS featuring extensive keyboard control, Markdown integrated email composition, advanced search conditions and drill-down search links, equally advanced smart mailboxes, automatic signature handling, cryptographic encryption/signing (OpenPGP and S/MIME), tagging, multiple notification methods, alternative message viewer layouts including a widescreen layout, flexible integration with third party applications, and much more."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

LAUNCH='no'

LATEST_FILENAME=$(curl -sfLS "https://updates.mailmate-app.com/archives/?C=M;O=D" \
| egrep 'MailMate_.*.tbz' \
| head -1 \
| sed -e 's#.*href="##g' -e 's#">.*##g')

# this will get us something like
# MailMate_r6226.tbz

URL="https://updates.mailmate-app.com/archives/$LATEST_FILENAME"

LATEST_VERSION=$(echo "$LATEST_FILENAME:t:r" | sed 's#MailMate_r##g')

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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
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

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		pgrep -x -q MailMate \
		&& LAUNCH='yes' \
		&& osascript -e 'tell application "MailMate" to quit'

		mv "$INSTALL_TO" "$HOME/.Trash/MailMate.$INSTALLED_VERSION.app"
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
		## NOTE: There are no release notes for these cutting edge betas
	# mv -vf "$RELEASE_NOTES_TXT" "$DIRNAME/$INSTALL_TO:t:r-${INSTALLED_VERSION}_${INSTALLED_BUILD}.txt"

fi

exit 0
#EOF
