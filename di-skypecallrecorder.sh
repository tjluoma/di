#!/bin/zsh -f
# Purpose: Download and install the latest version of Skype Call Recorder
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-22

	## You need to provide your own private URL to download Skype Call Recorder. You should have received this
	## in an email when you first registered it. So the question is: “How do you share a public script with private
	## information in it?”
	##
	## Answer: Put the secret bit in a separate file which is read into the main script.
	##
	## So, create a file "$HOME/.config/di/private/di-skypecallrecorder.txt" with a line like this in it:
	##
	## 	https://www.ecamm.com/cgi-bin/customercenter?u=you%40example%2Ecom&c=ABCDEF
	##
	#### Replace that with your actual URL
PRIVATE_FILE="$HOME/.config/di/private/di-skypecallrecorder.txt"

XML_FEED='https://www.ecamm.com/appcasts/callrecorder.xml'

HOMEPAGE="https://www.ecamm.com/mac/callrecorder/"

DOWNLOAD_PAGE="http://downloads.ecamm.com/CallRecorder.zip"

SUMMARY="Call Recorder records Skype audio and video calls directly to your Mac. (Note: Download page is for demo version.)"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# Can't use "https://www.ecamm.com/appcasts/callrecorder.xml" for downloading because it's just the demo
	# But we can get the version number from it.
LATEST_VERSION=$(curl -sfLS "$XML_FEED" | tr ' |/' '\012' | awk -F'"' '/sparkle:version/{print $2}')

	# And the release-notes URL

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep '<sparkle:releaseNotesLink>' \
	| head -1 \
	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')

if [[ "$LATEST_VERSION" = "" ]]
then
	echo "$NAME [Fatal Error]: \$LATEST_VERSION is empty. Cannot continue."
	exit 1
fi

NAME="$0:t:r"

INSTALL_TO="/Library/Audio/Plug-Ins/HAL/EcammAudioLoader.plugin/Contents/Plugins/CallRecorder.plugin"

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

fi

[[ -e "$PRIVATE_FILE" ]] && PRIVATE_URL=$(egrep -i '^http.*//www.ecamm.com/' "$PRIVATE_FILE")

if [ "$PRIVATE_URL" != "" ]
then
		# This is what we hope for:
		# if we get to this point, we know we need to do either an install or an update
		# AND we have an URL to work with.

	URL=$(curl -sfLS "$PRIVATE_URL" | tr '"' '\012' | egrep -i '^https://www.ecamm.com/.*/CallRecorder.*\.zip' | fgrep "$LATEST_VERSION")

else
	# These are the less-desirable options. All of these end with 'exit 1'

	if [ ! -e "$PRIVATE_FILE" ]
	then
			# no PRIVATE_FILE exists.

		echo "$NAME: Fatal Error. '\$PRIVATE_FILE' does not exist at '$PRIVATE_FILE'. Cannot continue. See '$0' for details on how to create it."

	elif [ "$PRIVATE_URL" = "" ]
	then
			# the PRIVATE_FILE exists
			# but the PRIVATE_URL is empty
		echo "$NAME: Fatal Error. '$PRIVATE_FILE' exists but does not contain a URL. Cannot continue."
	else
			# I'm not sure how we'd ever get here, but just in case we do, we should say something, at least
		echo "$NAME: Fatal Error. Cannot continue. (For unclear reasons, sorry.)"
	fi

	echo "$NAME: If you just want to download the demo version, you can do that here: <https://www.ecamm.com/mac/callrecorder/CallRecorder.zip>"

	exit 1
fi

FILENAME="$HOME/Downloads/SkypeCallRecorder-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	(lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ;
	 echo "\nSource: <$RELEASE_NOTES_URL>") | tee "$FILENAME:r.txt"

fi

	# The server doesn't do continued downloads, so if we find something where our download is supposed to go,
	# we need to test it to see if it is a) a working zip file -- which probably means that they've previously
	# downloaded the file, so we don't need to download it again, or b) an incomplete zip -- which probably
	# means that the file download has started previously, but did not complete.

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

		mv -vn "$FILENAME" "$HOME/Downloads/SkypeCallRecorder-BROKEN-EXAMINE.${TIME}.${LATEST_VERSION}.zip"
	fi
fi

if [[ ! -e "$FILENAME" ]]
then

	echo "$NAME: Downloading '$URL' to '$FILENAME':"

	UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15'

	curl -A "$UA" --fail --location --output "$FILENAME" "$URL"

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

echo "$NAME: Looking for 'Install Call Recorder.app' :"

APP=$(find "$UNZIP_TO" -maxdepth 2 -type d -iname 'Install Call Recorder.app' -print)

if [[ "$APP" == "" ]]
then
	echo "$NAME: Failed to find 'Install Call Recorder.app' in $UNZIP_TO"
	exit 1
fi

echo "$NAME: Found it at: '$APP'. Launching it now. Requires manual installation from here."

	# the app is an installer which needs user intervention, so the most we can do is just open it
open "$APP"

if [ ! -d "/Applications/Skype.app" -a ! -d "$HOME/Applications/Skype.app" ]
then

	if (( $+commands[di-skype.sh] ))
	then

		echo "$NAME: Skype is not installed. Running 'di-skype.sh' to install it."

		di-skype.sh

	else
		echo "$NAME: Skype is not installed. Go to <https://www.skype.com/en/get-skype/> for more information,"
		echo "	or use this link to download it directly: <https://get.skype.com/go/getskype-skypeformac>"
	fi
fi

exit 0
#
#EOF
