#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-26

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

zmodload zsh/stat

COUNT='0'

INSTALL_TO='/Applications/atMonitor.app'

function check_permissions {

	HELPER="$INSTALL_TO/Contents/Resources/atMonitorHelper"

	MODE=$(zstat -L +mode "$HELPER")

	if [ "$MODE" != "35309" ]
	then

		echo "$NAME: [WARNING!] atMonitor will not run without administrative permissions,"
		echo "	Specifically, the file '$HELPER' must be 'setuid root'."
		echo "	If you do not know what that means, you should learn before you grant it.\n"

		read -t 30 "?Do you want to set potentially dangerous permissions for ‘$HELPER’? [y/N] " ANSWER

		case "$ANSWER" in

			Y*|y*)

				echo "	If you are SURE that you want to set these permissions, enter your login"
				echo "	password when prompted:"

				sudo chown root "$HELPER"
				sudo chgrp admin "$HELPER"
				sudo chmod 4755 "$HELPER"

				EXIT="$?"

				if [ "$EXIT" = "0" ]
				then

					echo "$NAME: Successfully ran 'chmod 4755 '$HELPER' and 'sudo chown root:admin $HELPER"

				else
					echo "$NAME: FAILED to set 'sudo chmod 4755 $HELPER' (\$EXIT = $EXIT)"

					((COUNT++))
				fi
			;;

			*)
					echo "$NAME: Ok, _not_ setting permissions on '$HELPER'.\n\tBe warned that the app may refuse to run."
			;;

		esac
	fi
}

URL='https://www.dropbox.com/s/k7gaxu9fkvshe3b/atMonitor-2.8b_2.8.zip?dl=0'

FILENAME="$HOME/Downloads/atMonitor-2.8b_2.8.zip"

SHA_URL='https://www.dropbox.com/s/x8akrwvccgw0jdm/atMonitor-2.8b_2.8.sha256.txt?dl=0'

SHA_FILE="$FILENAME:h/atMonitor-2.8b_2.8.sha256.txt"

LATEST_VERSION="2.8b"

LATEST_BUILD="2.8"

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

		check_permissions

		exit $COUNT
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

cd "$FILENAME:h"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 1

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 1

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 1

curl --continue-at - --fail --location --output "$SHA_FILE" "$SHA_URL"

shasum -c "$SHA_FILE"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' passed sha256 validation."

else
	echo "$NAME: '$FILENAME' _FAILED_ sha256 validation. You should not use it."
	echo "	Try downloading it again from <$URL>"

	exit 1
fi

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

check_permissions

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit $COUNT

#EOF
