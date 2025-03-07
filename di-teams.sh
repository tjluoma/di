#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of Microsoft Teams
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2025-03-07
# Verified:	2025-03-07

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Microsoft Teams.app"

	# Adapted from:
	# https://github.com/Homebrew/homebrew-cask/blob/master/Casks/m/microsoft-teams.rb
	# I just decided on putting the '7' there as a placeholder, and it works.
	# but obviously it could break in the future
LINK="https://config.teams.microsoft.com/config/v1/MicrosoftTeams/7?environment=prod&audienceGroup=general&teamsRing=general&agent=TeamsBuilds"

INFO=($(curl  -sfLS "$LINK" \
		| sed 	-e 's#.*"WebView2":{"macOS":{"latestVersion":"##g' \
				-e 's#"}}.*##g' \
				-e 's#","buildLink":"# #g'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"  >>/dev/stderr

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

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.pkg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

if (( $+commands[pkginstall.sh] ))
then
		# use 'pkginstall.sh' if it exists

	pkginstall.sh "$FILENAME"

else
		# fall back to either `sudo installer` or macOS's installer app
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1 \
	|| open -b com.apple.installer "$FILENAME"

fi

exit 0
#
#EOF