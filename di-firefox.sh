#!/bin/zsh -f
# Purpose: Download and install/update the latest version of Firefox from <https://www.mozilla.org/en-US/firefox/new/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-25

OG_NAME="$0:t:r"

SCRIPT_NAME="$0:t"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function do_nightly {

	NAME="$OG_NAME (nightly releases)"
	PRODUCT='nightly-latest'
	SHORTNAME='FirefoxNightly'
	INSTALL_TO="/Applications/Firefox Nightly.app"
}

function do_developer {

	NAME="$OG_NAME (developer releases)"
	PRODUCT='devedition-latest'
	SHORTNAME='FirefoxDeveloperEdition'
	INSTALL_TO="/Applications/Firefox Developer Edition.app"
}

function do_beta {

	NAME="$OG_NAME (beta releases)"
	PRODUCT='beta-latest'
	SHORTNAME='FirefoxBeta'
	INSTALL_TO="/Applications/Firefox.app"
}

function do_regular {

	NAME="$OG_NAME (regular releases)"
	PRODUCT='latest'
	SHORTNAME='Firefox'
	INSTALL_TO="/Applications/Firefox.app"
}

function do_usage {

cat <<EOINPUT
# $SCRIPT_NAME Usage:

$SCRIPT_NAME takes several optional arguments:

	-n or --nightly 	to force a check _only_ for nightly builds
	-d or --developer	to force a check _only_ for developer builds
	-b or --beta		to force a check _only_ for beta builds
	-r or --regular  	to force a check for “regular” builds (i.e. none of the above)

	-h or --help		show this help

If several arguments are given, only the last will be acted on.

If you want to check more than one option, call the script more than once. For example, if you wanted
to check for both the beta and developer builds, you would use this:

	$SCRIPT_NAME --beta ; $SCRIPT_NAME -d

## Checking for Developer Edition builds:

	If the script is called _without_ any arguments, and it finds

		"/Applications/Firefox Developer Edition.app" or "$HOME/Applications/Firefox Developer Edition.app"

	and/or if it finds anything at

		"$HOME/.config/di/prefers/firefox-developer.txt"

	it will automatically run '$SCRIPT_NAME --developer'

## Checking for Nightly builds:

If the script is called _without_ any arguments, and it finds

	  "/Applications/Firefox Nightly.app" or "$HOME/Applications/Firefox Nightly.app"

	and/or if it finds anything at

		"$HOME/.config/di/prefers/firefox-nightly.txt"

it will automatically run '$SCRIPT_NAME --nightly'

## Checking for Beta releases

If the script is called _without_ any arguments, it will check for _beta_ releases if it finds anything at

	"$HOME/.config/di/prefers/firefox-beta.txt"

If it does not find that file, it assumes that you want to check for regular (non-beta) versions of Firefox.

{end of usage info}
EOINPUT

exit 0

}



USER_SELECTED=''

for ARGS in "$@"
do
	case "$ARGS" in
		-n|--night*)
				shift
				USER_SELECTED='nightly'
				do_nightly
		;;

		-d|--dev*)
				USER_SELECTED='developer'
				do_developer
				shift
		;;

		-b|--beta)
				USER_SELECTED='beta'
				do_beta
				shift
		;;

		-r|--reg*)
				USER_SELECTED='regular'
				do_regular
				shift
		;;

		-h|--help|help|--usage)
				do_usage | "${PAGER-less}"
				exit 0
		;;

		-*|--*)
				echo "$OG_NAME: Don't know what to do with arg: $1"
				echo "	Try '$SCRIPT_NAME --help' for usage information."
				exit 1
		;;

	esac

done # for args

if [[ "$USER_SELECTED" == "" ]]
then
		# If this script was called without any specific build requested
		# then check to see:
		#
		# a) if the user has create a file indicating which build(s) they want
		# b) if the user has already installed the Nightly or Developer Edition
		#
		# if A or B, we call the script again (this is where it gets recursive)
		# except this time we tell it specifically to check for the version
		# that we found in either A or B.

	[ -e "$HOME/.config/di/prefers/firefox-nightly.txt"   \
	  -o -d "/Applications/Firefox Nightly.app" \
	  -o -d "$HOME/Applications/Firefox Nightly.app" \
	] && "$0" --nightly

	[ -e "$HOME/.config/di/prefers/firefox-developer.txt" \
	  -o -d "/Applications/Firefox Developer Edition.app" \
	  -o -d "$HOME/Applications/Firefox Developer Edition.app" \
	] && "$0" --developer

		# have to choose EITHER beta OR regular,
		# because they both do same INTSTALL_TO
	if [[ -e "$HOME/.config/di/prefers/firefox-beta.txt" ]]
	then
		do_beta
	else
		do_regular
	fi
fi

URL=$(curl -sSfL --head "https://download.mozilla.org/?product=firefox-${PRODUCT}-ssl&os=osx&lang=en-US" | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

if [ "$PRODUCT" = "nightly-latest" ]
then
	LATEST_VERSION=$(echo "$URL:t:r" | sed 's#firefox-##g ; s#.en-US.mac##g')
else
	LATEST_VERSION=$(echo "$URL" | sed 's#.*/releases/##g ; s#/.*##g')
fi

	# If either of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$SHORTNAME-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}.app"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
