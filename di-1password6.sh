#!/bin/zsh -f
# Purpose: Download and install the latest version of 1Password 6 (note that 1Password 7 is also available)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/1Password 6.app'

# 	https://app-updates.agilebits.com/download/OPM4
# currently redirects to:
# 	https://c.1password.com/dist/1P/mac4/1Password-6.8.9.pkg

URL=$(curl -sfL --head 'https://app-updates.agilebits.com/download/OPM4' | awk -F' |\r' '/^.ocation/{print $2}' | tail -1)

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#1Password-##g' | tr -dc '[0-9]\.')

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
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
		echo "$NAME: Up To Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/1Password-${LATEST_VERSION}.pkg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

function die
{
	echo "$NAME: $@"
	exit 1
}

if (( $+commands[unpkg.py] ))
then
	# Get unpkg.py from https://github.com/tjluoma/unpkg/blob/master/unpkg.py

	echo "$NAME: running 'unpkg.py' on '$FILENAME':"

	UNPKG=`unpkg.py "$FILENAME" 2>&1`

	[[ "$UNPKG" == "" ]] && die "unpkg.py failed"

	EXTRACTED_TO=$(echo "$UNPKG" | egrep '^Extracted to ' | sed 's#Extracted to "##g ; s#".##g')

	[[ "$EXTRACTED_TO" == "" ]] && die "unpkg.py failed (EXTRACTED_TO empty)"

	if [[ -e "$INSTALL_TO" ]]
	then
			# If there's an existing installation, move it to the trash
		mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}.app"
	fi

	mv -vf "$EXTRACTED_TO/$INSTALL_TO:t" "$INSTALL_TO" || die 'move failed'

elif (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME" || die "pkginstall.sh failed"

else

	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1 || die "sudo installer failed"
fi

exit 0
#EOF
