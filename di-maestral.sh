#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-09-06

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Maestral.app"

XML_FEED='https://maestral.app/appcast.xml'

TEMPFILE="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.txt"

curl -sfLS "$XML_FEED" | awk '/<item>/{i++}i==1' >| "$TEMPFILE"

# echo "$TEMPFILE"

LATEST_VERSION=$(egrep '<sparkle:shortVersionString>.*</sparkle:shortVersionString>' "$TEMPFILE" \
				| sed -e 's#.*<sparkle:shortVersionString>##g' -e 's#</sparkle:shortVersionString>.*##g')

LATEST_BUILD=$(egrep '<sparkle:version>.*</sparkle:version>' "$TEMPFILE" \
				| sed -e 's#.*<sparkle:version>##g' -e 's#</sparkle:version>.*##g')

MIN_VERSION=$(egrep '<sparkle:minimumSystemVersion>.*</sparkle:minimumSystemVersion>' "$TEMPFILE" \
				| sed -e 's#.*<sparkle:minimumSystemVersion>##g' -e 's#</sparkle:minimumSystemVersion>.*##g')

URL=$(fgrep 'url="https://github.com/SamSchott/maestral/releases/download/' "$TEMPFILE" \
				| sed -e 's#.*url="##g' -e 's#"##g')

	# If any of these are blank, we cannot continue
if [ "$MIN_VERSION" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" ]
then
	echo "$NAME: Error: bad data received:
	MIN_VERSION: $MIN_VERSION
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL"  >>/dev/stderr

	exit 2
fi

OS_VER=$(sw_vers -productVersion)

autoload is-at-least

is-at-least "$MIN_VERSION" "$OS_VER"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
		# This is at least the minimum (or later)
	echo "$NAME: OS version '$OS_VER' is at least '$MIN_VERSION'."

elif [[ "$EXIT" == "1" ]]
then
		# This is lower than the minimum
	echo "$NAME: OS version '$OS_VER' does not meet minimum requirement of '$MIN_VERSION'."

	MIN_VERSION: $MIN_VERSION
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL" >>/dev/stderr

	exit 2

fi












#         <sparkle:version>25</sparkle:version>
#         <sparkle:shortVersionString>1.4.8</sparkle:shortVersionString>
#         <sparkle:minimumSystemVersion>10.14</sparkle:minimumSystemVersion>

# https://github.com/SamSchott/maestral/releases/latest

# Note that version numbers are in a different location in this feed
# https://github.com/SamSchott/maestral/issues/451



exit 0
#EOF
