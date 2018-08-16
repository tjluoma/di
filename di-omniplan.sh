#!/bin/zsh -f
# Purpose: Download and install the latest version of OmniPlan
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-10

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniPlan.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

LAUNCH='no'

## Note: Downloads are available in tbz2 and dmg but dmg has EULA so I use tbz2

XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniPlan3"

# Don't indent or you'll break the 'sed' command

# There's also a <omniappcast:buildVersion> ~ </omniappcast:buildVersion>
# which corresponds to 'CFBundleVersion' but the number is too absurdly long to be useful

INFO=($(curl -sfL "$XML_FEED" 2>&1 \
| sed 's#<#\
<#g' \
| tr -s ' ' '\012' \
| egrep '<omniappcast:marketingVersion>|url=.*\.tbz2' \
| head -2 \
| tr -s '>|"' ' ' \
| awk '{print $NF}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Bad data received from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info"  CFBundleShortVersionString 2>/dev/null || echo '0'`

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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://itunes.apple.com/us/app/omniplan-3/id1040002810?mt=12> or"
		echo "	<macappstore://itunes.apple.com/us/app/omniplan-3/id1040002810>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

fi

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| egrep '<omniappcast:releaseNotesLink>.*</omniappcast:releaseNotesLink>' \
		| head -1 \
		| sed 's#.*<omniappcast:releaseNotesLink>##g; s#</omniappcast:releaseNotesLink>.*##g')

	echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n"

	curl -sfL "$RELEASE_NOTES_URL" \
	| sed '1,/<article>/d; /<\/article>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin

	echo "\nSource: <$RELEASE_NOTES_URL>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.tbz2"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: unpacking '$FILENAME' to '$UNZIP_TO/':"

tar -x -C "$UNZIP_TO" -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" != "0" ]
then

	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"
		exit 1
	fi
fi

mv -vf "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation of $INSTALL_TO successful"
	exit 0

else
	echo "$NAME: tar failed (\$EXIT = $EXIT)"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0

#EOF
