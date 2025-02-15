#!/usr/bin/env zsh -f
# Purpose: Install 1Password version 8 (note: will not update an installed version)
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2025-02-15
# Verified:	2025-02-15

NAME="$0:t:r"

PREFLIGHT="$HOME/.config/di/preflight.sh"

[[ -s "$PREFLIGHT" ]] && source "$PREFLIGHT"

	## NOTE: The app _must_ be installed at /Applications/ to work
INSTALL_TO="/Applications/1Password.app"

HOMEPAGE="https://1password.com"

DOWNLOAD_PAGE="https://1password.com/downloads/"

DIRECT_DOWNLOAD='https://downloads.1password.com/mac/1Password.zip'

SUMMARY="Go ahead. Forget your passwords. 1Password remembers them all for you. Save your passwords and log in to sites with a single click. It's that simple."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

###############################################################################################

if [[ -e "$INSTALL_TO" ]]
then

	echo "$NAME: Fatal error: 1Password is already installed at '$INSTALL_TO'.

	This script will not update 1Password 8 because I have not found any good way to find the latest version.
	Therefore it will only do a first install of 1Password 8."

	exit 0

fi

URL='https://downloads.1password.com/mac/1Password.zip'

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/1PasswordInstalller.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

TEMPDIR=$(mktemp -d "${TMPDIR-/tmp/}${NAME-$0:r}-XXXXXXXX")

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TEMPDIR/"

	mv -fv "$FILENAME:r".* "$TEMPDIR/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TEMPDIR}/${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful to '$UNZIP_TO'"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

	# Here we just launch the installer which will download and install the app from here
open -a "${UNZIP_TO}/1Password Installer.app"

exit 0
#EOF
