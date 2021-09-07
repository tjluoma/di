#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-08-04

NAME="$0:t:r"

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/MailMate.app"

URL_TO_CHECK='https://updates.mailmate-app.com/arm64/11.5/test'

INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion)

LATEST_VERSION=$(curl -sfLS "$URL_TO_CHECK" \
				| sed -e "s#.*revision = '##g" -e "s#'.*##g")

[[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]] && echo "$NAME: Up to date: $INSTALLED_VERSION" && exit 0

autoload msg

GROWL_APP='MailMate'

msg --sticky "New version of MailMate available: $LATEST_VERSION"

URL=$(curl -sfLS "$URL_TO_CHECK" | sed -e "s#.*url = '##g" -e "s#'.*##g")

FILENAME="$HOME/Downloads/MailMate-${LATEST_VERSION}.tbz"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

open -R "$FILENAME"

exit 0
#EOF
