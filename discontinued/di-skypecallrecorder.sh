#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Skype Call Recorder
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-22


	# you MUST customize this URL to be your URL from ECamm
	# it ends with your email address (URL encoded) and a 6 digit personal code
PRIVATE_URL='https://www.ecamm.com/cgi-bin/customercenter?u=USER%40EXAMPLE%2ECOM&c=XXXXXX'

PRIVATE_URL='https://www.ecamm.com/cgi-bin/customercenter?u=me%40tjluoma%2Ecom&c=YPJ349'

## you should not have to change anything below this line



	# This is the public RSS feed for call recorder which we use for release notes
XML_FEED='https://www.ecamm.com/appcasts/callrecorder.xml'

	# this helps curl pretend that it's Safari
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.1 Safari/605.1.15'

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# this will get us the actual URL for the actual download
URL=$(curl --user-agent "$UA" -sfLS "$PRIVATE_URL" | tr '"' '\012' | egrep -i '^https://www.ecamm.com/.*/CallRecorder.*\.zip')

	# we parse out the version number from that URL
LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

	# this is the URL to the release notes
RELEASE_NOTES_URL=$(curl --user-agent "$UA" -sfL "$XML_FEED" \
	| fgrep '<sparkle:releaseNotesLink>' \
	| head -1 \
	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')


if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME [Fatal Error]: \$URL is '$URL' and \$LATEST_VERSION is '$LATEST_VERSION'. Cannot continue."
	exit 1
fi

NAME="$0:t:r"

	# this is where Call Recorder gets installed to
INSTALL_TO="/Library/Application Support/EcammVideoPlugins/CallRecorder.plugin"

	## if Call Recorder is already installed
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

URL=$(curl --user-agent "$UA" -sfLS "$PRIVATE_URL" | tr '"' '\012' | egrep -i '^https://www.ecamm.com/.*/CallRecorder.*\.zip' | fgrep "$LATEST_VERSION")

FILENAME="$HOME/Downloads/SkypeCallRecorder-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then
		# if you have Lynx installed, this will show you release notes
	(lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ;
	 echo "\nSource: <$RELEASE_NOTES_URL>") | tee "$FILENAME:r.txt"
else
		# if you don't have Lynx, a URL to the release notes
	echo "Release Notes can be found at $RELEASE_NOTES_URL"  | tee "$FILENAME:r.txt"
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

	# If we don't have the file, download the file
if [[ ! -e "$FILENAME" ]]
then

	echo "$NAME: Downloading '$URL' to '$FILENAME':"

		# here's where the downloading happens
	curl --user-agent "$UA" --fail --location --output "$FILENAME" "$URL"

	EXIT="$?"

		## exit 22 means 'the file was already fully downloaded'
	[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

	[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

	[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

fi

	# Now that we have it downloaded, lets unpack it
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
	# if it doesn't open, at least reveal it in the Finder
open "$APP" || open -R "$APP"

exit 0
#
#EOF
