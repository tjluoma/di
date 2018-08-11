#!/bin/zsh -f
# Purpose: Download the latest version of RDM from <https://github.com/avibrazil/RDM/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-10

NAME="$0:t:r"

INSTALL_TO="/Applications/RDM.app"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function die
{
	echo "$NAME: $@"
	exit 1
}

URL=$(curl -sfL "http://avi.alkalay.net/software/RDM/" \
	| fgrep -i '.pkg' \
	| tail -1 \
	| awk -F'"' '/RDM/{print "http://avi.alkalay.net/software/RDM/"$2}')

if [[ "$URL" == "" ]]
then
	URL='http://iusethis.luo.ma/rdm/RDM-2.2.pkg'
fi

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: \$LATEST_VERSION is empty".
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

RELEASE_NOTES_URL='https://github.com/avibrazil/RDM/'

echo "$NAME: Release notes are not available, but checkout ${RELEASE_NOTES_URL} for details."

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.pkg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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

	mv -vf "$EXTRACTED_TO/Applications/RDM.app" "$INSTALL_TO" || die 'move failed'

	zmodload zsh/datetime

	TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

		# Move what should be empty directories to the trash
	mv -vf "$EXTRACTED_TO" "$HOME/.Trash/$EXTRACTED_TO:t_${TIME}"

	[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

elif (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$FILENAME"
else
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1
fi

exit 0
#EOF
