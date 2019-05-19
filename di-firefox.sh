#!/bin/zsh -f
# Purpose: Download and install/update the latest version of Firefox from <https://www.mozilla.org/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-25

NAME="$0:t:r"

OG_NAME="$NAME"

HOMEPAGE="https://www.mozilla.org/en-US/firefox"

DOWNLOAD_PAGE="https://www.mozilla.org/en-US/firefox/download/thanks/"

SUMMARY="Firefox offers a fast, safe Web browsing experience. Browse quickly, securely, and effortlessly. With its industry-leading features, Firefox is the choice of Web development professionals and casual users alike."

SCRIPT_NAME="$0:t"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function do_nightly {

	NAME="$OG_NAME (nightly releases in ${FF_LANG})"
	PRODUCT='nightly-latest'
	SHORTNAME='FirefoxNightly'
	INSTALL_TO="/Applications/Firefox Nightly.app"

	[[ "$FF_LANG" != "en-US" ]] && echo "$NAME: Please note, the nightly builds may only be available in en-US."
}

function do_developer {

	NAME="$OG_NAME (developer releases in ${FF_LANG})"
	PRODUCT='devedition-latest'
	SHORTNAME='FirefoxDeveloperEdition'
	INSTALL_TO="/Applications/Firefox Developer Edition.app"
}

function do_beta {

	NAME="$OG_NAME (beta releases in ${FF_LANG})"
	PRODUCT='beta-latest'
	SHORTNAME='FirefoxBeta'
	INSTALL_TO="/Applications/Firefox.app"
}

function do_regular {

	NAME="$OG_NAME (regular releases in ${FF_LANG})"
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

## A Final Word About Language/Country Codes

This script defaults to 'en-US' as a country/language choice, but you can override that by putting the
appropriate language/country code into a plain-text file at:

	"$HOME/.config/di/prefers/firefox-language.txt"

Just the code, nothing else. For example, if you wanted to get the 'Canadian' version of Firefox,
then the contents of the "$HOME/.config/di/prefers/firefox-language.txt" file should be:

	ca

and nothing else.

EOINPUT

exit 0

}

LANGUAGE_FILE="$HOME/.config/di/prefers/firefox-language.txt"

if [[ -e "$LANGUAGE_FILE" ]]
then
		# if we find the file, use its contents as the language/country code, which can apparently be any one of a lot (see below)

	FF_LANG=$((egrep -v "^[	 ]*#|^$|^[ 	]*$" "$LANGUAGE_FILE" 2>/dev/null || echo 'en-US') \
		| awk '{print $1}' | head -1 | tr -dc '[:alpha:]-')


case "${FF_LANG}" in

en-GB|af|an|ar|ast|az|azz|be|bg|bn-BD|bn-IN|bs|ca|cak|cs|cy|da|de|dsb|el|en-CA|en-US|eo|es-AR|es-CL|es-ES|es-MX|et|eu|fa|fi|fr|fy-NL|ga-IE|gn|gu-IN|he|hi-IN|hr|hsb|hu|hy-AM|ia|id|is|it|ja|ka|kab|kk|ko|lij|lt|ml|mr|ms|my|nb-NO|nl|nn-NO|pa-IN|pl|pt-BR|pt-PT|rm|ro|ru|sk|sl|sq|sr|sv-SE|ta|te|th|tr|trs|uk|uz|vi|zh-CN|zh-TW)
		:
		# If we get here, we have a received a valid FF_LANG option
		# To get a current list of countries/languages Firefox is available in, run this command:
		#
		#	curl -sfLS "https://www.mozilla.org/en-US/firefox/all/"  \
		#	| fgrep '<option lang=' \
		#	| sed 's#.*<option lang="##g ; s#" .*##g'
		#
		# And it will output the entire list
	;;

	*)
		GIVEN_LANG="${FF_LANG}"

		echo "$NAME: [info] '$GIVEN_LANG' is not on my list of known countries/languages. Checking Mozilla.org..."

			# The nice thing about doing this check is that it is case-INsenitive
			# so if someone put in 'en-gb' instead of 'en-GB', this will find it
			#
			# We _could_ just do this every time instead of having a list of “known”
			# languages above, but that seems a bit wasteful. Why not cache the known-data
			# rather than always having to make another hit on the website?
		FF_LANG=$(curl -sfLS "https://www.mozilla.org/en-US/firefox/all/"  \
		| fgrep '<option lang=' \
		| sed 's#.*<option lang="##g ; s#" .*##g' \
		| egrep -i "^${FF_LANG}$")

		if [[ "${FF_LANG}" == "" ]]
		then
			echo "$NAME: '$GIVEN_LANG' is NOT a valid country/language code for Firefox. Please choose from one of these options:\n"

			curl -sfLS "https://www.mozilla.org/en-US/firefox/all/"  \
				| fgrep '<option lang=' \
				| sed 's#.*<option lang="##g ; s#" .*##g' \
				| tr -s '\012' ' '

			echo "\n\n	and update the file '$LANGUAGE_FILE' with the appropriate country/language code."

			exit 1
		fi


		if [[ "$GIVEN_LANG" == "$FF_LANG" ]]
		then
			echo "$NAME: [info] Mozilla added '$FF_LANG' support after this script was written. My developer should update me."
		else
			echo "$NAME: [info] Found '$FF_LANG'. You may want to update '$LANGUAGE_FILE' with your choice."
		fi


		# If we get here, then we were given a valid FF_LANG option, it just was not in our list of known-language/country-codes
		# which was compiled on 2018-08-25 and should probably be updated periodically.
	;;

esac

else
		# If we get here, there was no language/country code file, so we default to "en-US". Because America.
		#
		# (Please note that “Because America” should be read ironically.)
	FF_LANG='en-US'
fi

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

MY_CUSTOMIZED_URL="https://download.mozilla.org/?product=firefox-${PRODUCT}-ssl&os=osx&lang=${FF_LANG}"

URL=$(curl -sSfL --head "$MY_CUSTOMIZED_URL" | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

if [ "$PRODUCT" = "nightly-latest" ]
then
	LATEST_VERSION=$(echo "$URL:t:r" | sed 's#firefox-##g ; s#.${FF_LANG}.mac##g')
else
	LATEST_VERSION=$(echo "$URL" | sed 's#.*/releases/##g ; s#/.*##g')
fi

# echo "$NAME: [debug]
#
# MY_CUSTOMIZED_URL: $MY_CUSTOMIZED_URL
# URL: $URL
# LATEST_VERSION: $LATEST_VERSION
#
# "

	# If either of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL

	MY_CUSTOMIZED_URL: $MY_CUSTOMIZED_URL
	PRODUCT: $PRODUCT
	FF_LANG: $FF_LANG
	USER_SELECTED: $USER_SELECTED (Note: will always be empty, _unless_ an --arg was provided by the user)
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

FILENAME="$HOME/Downloads/$SHORTNAME-${FF_LANG}-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

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
