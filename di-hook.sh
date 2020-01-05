#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of Hook from <https://hookproductivity.com/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-10-12

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Hook.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/Hook.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# XML_FEED='https://updates.devmate.com/com.cogsciapps.hook.xml'
#
# INFO=($(curl -sfLS "$XML_FEED" \
# 		| awk '/<item>/{i++}i==1' \
# 		| tr -s '\t| ' '\012' \
# 		| egrep -i '<sparkle:releaseNotesLink>|url=|sparkle:version=|sparkle:shortVersionString=' \
# 		| sort \
# 		| tr '<|>|"' ' ' \
# 		| awk '{print $2}'))
#
#
# 	RELEASE_NOTES_URL="$INFO[1]"
#
# 	LATEST_VERSION="$INFO[2]"
#
# 	LATEST_BUILD="$INFO[3]"
#
# 	URL="$INFO[4]"

XML_FEED="https://api.appcenter.ms/v0.1/public/sparkle/apps/a77a1a87-7d69-435d-90ea-7365b2f7bddb"

INFO=$(curl -sfLS "$XML_FEED" \
	| sed 's#^[	 ]*##g' \
	| tr -s '\012|\r| ' ' ' \
	| sed -e 's#> <#><#g' -e 's#> #>#g' -e 's# <#<#g')

LATEST_BUILD=$(echo "$INFO" | sed -e 's#.* sparkle:version="##g' -e 's#" .*##g')

LATEST_VERSION=$(echo "$INFO" | sed -e 's#.* sparkle:shortVersionString="##g' -e 's#" .*##g')

URL=$(echo "$INFO" | sed -e 's#.* url="##g' -e 's#" .*##g')

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

# echo "
# 	INFO: $INFO
# 	LATEST_VERSION: $LATEST_VERSION
# 	LATEST_BUILD: $LATEST_BUILD
# 	URL: $URL
# 	RELEASE_NOTES:
# ---
# $RELEASE_NOTES
# ---
# "

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
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	# 	( lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" \
	#  	  | sed 's#____________________________#_#g' ;\
	# 	echo "\nURL: $URL" ;\
	#  	) | tee "$FILENAME:r.txt"

	RELEASE_NOTES=$(echo "$INFO" \
		| sed -e 's#.*<description>##g' -e 's#</description>.*##g' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin )

	echo "${RELEASE_NOTES}\n\nURL: $URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

echo "$NAME: Accepting EULA and mounting $FILENAME (sorry if this opens a Finder window. It's not my fault!)"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

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
	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$TRASH'. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi
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
