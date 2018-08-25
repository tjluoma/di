#!/bin/zsh -f
# Purpose: Download and install the latest version of PhoneView from <https://www.ecamm.com/mac/phoneview/>
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2018-08-25


## This is the file that has your private URL in it, formatted like this:
# PRIVATE_URL='http://www.ecamm.com/cgi-bin/customercenter?u=YOU%40EXAMPLE%2ECOM&c=YOURCODE'

PRIVATE_FILE="$HOME/.config/di/private/di-phoneview.txt"

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		You shouldn't have to change anything below this line
#


INSTALL_TO='/Applications/PhoneView.app'

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# this will only let you download the demo version of the app
	# but it's handy for getting the current version number
XML_FEED='https://www.ecamm.com/appcasts/phoneview.xml'

LATEST_VERSION=$(curl -sfLS "$XML_FEED" \
	| tr ' |/' '\012' \
	| awk -F'"' '/sparkle:version/{print $2}')

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep '<sparkle:releaseNotesLink>' \
	| head -1 \
	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')

	# If this is blank, we cannot continue
if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: Error: bad data received. LATEST_VERSION is empty. Cannot continue."

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Get the installed version, if any, otherwise set it to zero
	INSTALLED_VERSION=$(defaults read /Applications/PhoneView.app/Contents/Info CFBundleShortVersionString)

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

	IS_INSTALLED='yes'
else
	IS_INSTALLED='no'
fi


[[ -e "$PRIVATE_FILE" ]] && source "$PRIVATE_FILE"

if [ "$IS_INSTALLED" = 'yes' -a "$PRIVATE_URL" != "" ]
then

	URL=$(curl -sfLS "$PRIVATE_URL" | tr '"' '\012' | egrep -i '^https://www.ecamm.com/.*\.zip')

elif [ "$IS_INSTALLED" = 'yes' -a "$PRIVATE_URL" = "" ]
then
	if [ -e "$PRIVATE_FILE" ]
	then
		echo "$NAME: Fatal Error. '$PRIVATE_FILE' exists but does not contain 'PRIVATE_URL='. Cannot continue."
		exit 1
	else
		echo "$NAME: Fatal Error. '$PRIVATE_FILE' does not exist. Cannot continue. See '$0' for details on how to create it."
		exit 1
	fi

elif [ "$IS_INSTALLED" = 'no' -a "$PRIVATE_URL" != "" ]
then

	URL=$(curl -sfLS "$PRIVATE_URL" | tr '"' '\012' | egrep -i '^https://www.ecamm.com/.*\.zip')

elif [ "$IS_INSTALLED" = 'no' -a "$PRIVATE_URL" = "" ]
then

	URL='https://downloads.ecamm.com/PhoneView.zip'
	DEMO="-DEMO"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r${DEMO}-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	(lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ;
	 echo "\nSource: <$RELEASE_NOTES_URL>") | tee -a "$FILENAME:r.txt"
fi

if [[ "$URL" == "" ]]
then
	echo "$NAME [Fatal Error]: \$URL is empty. Cannot continue."
	exit 1
fi

	# The server doesn't do 'continued' or resumed downloads, so if the file exists already, we need
	# to check to see if we can use it, and if not, replace it.
if [[ -e "$FILENAME" ]]
then
	(command unzip -qqt "$FILENAME" 2>&1) >/dev/null

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then
		echo "$NAME: $FILENAME already exists as valid .zip. Using it."

	else

		echo "$NAME: '$FILENAME' exists but is not a valid .zip file. Renaming it and re-downloading it."

			# Really, we should just delete / trash the file, but I'm loathe to do that on someone else's computer.
			# so we'll rename it and let them deal with it.

		zmodload zsh/datetime

		TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

		function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

		mv -vn "$FILENAME" "$HOME/Downloads/PhoneView${DEMO}-BROKEN-EXAMINE.${TIME}.${LATEST_VERSION}.zip"
	fi
fi

if [[ ! -e "$FILENAME" ]]
then

	echo "$NAME: Downloading '$URL' to '$FILENAME':"

	UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15'

	curl -A "$UA" --progress-bar --fail --location --output "$FILENAME" "$URL"

	EXIT="$?"

		## exit 22 means 'the file was already fully downloaded'
	[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

	[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

	[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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
mv -vn "$UNZIP_TO/$INSTALL_TO:t:r/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#
#EOF
