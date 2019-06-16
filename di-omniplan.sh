#!/bin/zsh -f
# Purpose: Download and install the latest version of OmniPlan (3)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-10

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniPlan.app'

HOMEPAGE="https://www.omnigroup.com/omniplan"

DOWNLOAD_PAGE="https://www.omnigroup.com/download/latest/omniplan/"

SUMMARY="Project planning made painless."

LAUNCH='no'

## Note: Downloads are available in tbz2 and dmg but dmg has EULA so I use tbz2

XML_FEED="http://update.omnigroup.com/appcast/com.omnigroup.OmniPlan3"

INFO=($(curl -sfL "$XML_FEED" \
		| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0  \
		| egrep '<omniappcast:releaseNotesLink>|<omniappcast:marketingVersion>|url=.*\.tbz2' \
		| head -3 \
		| sort \
		| sed \
			-e 's#.*url="##g ; s#".*##g' \
			-e 's#<omniappcast:marketingVersion>##g ; s#<\/omniappcast:marketingVersion>##g' \
			-e 's#<omniappcast:releaseNotesLink>##g ; s#<\/omniappcast:releaseNotesLink>##g'))

URL="$INFO[1]"
LATEST_VERSION="$INFO[2]"
RELEASE_NOTES_URL="$INFO[3]"

if [ "$URL" = "" -o "$LATEST_VERSION" = "" -o "$RELEASE_NOTES_URL" = "" ]
then
	echo "$NAME: Bad data received from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	RELEASE_NOTES_URL: $RELEASE_NOTES_URL
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
		echo "	See <https://apps.apple.com/us/app/omniplan-3/id1040002810?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/omniplan-3/id1040002810>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.tbz2"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n" ;
	curl -sfL "$RELEASE_NOTES_URL" \
	| sed '1,/<article>/d; /<\/article>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

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
