#!/bin/zsh -f
# Purpose: Download 1Password 6 or 7 depending on OS version or what's already installed
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

V6_INSTALL_TO='/Applications/1Password 6.app'
V7_INSTALL_TO='/Applications/1Password 7.app'

function do_os_check {

	OS_VER=$(sw_vers -productVersion)

	OS_MINIMUM='10.12.6'

	autoload is-at-least

	is-at-least "$OS_MINIMUM" "$OS_VER"

	IS_AT_LEAST="$?"

	if [ "$IS_AT_LEAST" != "0" ]
	then
			# Cannot use version 7
		CAN_USE_7='no'

		echo "$NAME: Cannot use 1Password 7 with $OS_VER (requires at least $OS_MINIMUM). Using 1Password 6 instead."

		use_v6

	else
		CAN_USE_7='yes'
	fi
}

function use_v6 {

	if [[ -e "$V7_INSTALL_TO" ]]
	then
		echo "$NAME: $V7_INSTALL_TO is installed. Cannot have both installed at the same time. To install 1Password 6, please remove 1Password 7."
		exit 0
	fi

	ASTERISK='(Note that version 7 is also available.)'
	USE_VERSION='6'
	INSTALL_TO='/Applications/1Password 6.app'

	# 	https://app-updates.agilebits.com/download/OPM4
	# currently redirects to:
	# 	https://c.1password.com/dist/1P/mac4/1Password-6.8.9.pkg

	URL=$(curl -sfL --head 'https://app-updates.agilebits.com/download/OPM4' | awk -F' |\r' '/^.ocation/{print $2}' | tail -1)

	LATEST_VERSION=$(echo "$URL:t:r" | sed 's#1Password-##g' | tr -dc '[0-9]\.')

}

function use_v7 {

	do_os_check

	if [[ "$CAN_USE_7" == "yes" ]]
	then

		USE_VERSION='7'
		INSTALL_TO='/Applications/1Password 7.app'

		PREFERS_BETAS_FILE="$HOME/.config/di/1Password-prefer-betas.txt"

		if [[ -e "$PREFERS_BETAS_FILE" ]]
		then

			URL=$(curl -sfL "https://app-updates.agilebits.com/product_history/OPM7" |\
				fgrep .pkg |\
				fgrep -i beta |\
				head -1 |\
				sed 's#.*a href="##g; s#">download</a>##g')

			LATEST_VERSION=$(echo "$URL:t:r" | sed 's#.*1Password-##g' )

			NAME="$NAME (beta releases)"

			BETAS='yes'
		else
			BETAS='no'

			DL_URL='https://app-updates.agilebits.com/download/OPM7'

			URL=$(curl -sfL --head "$DL_URL" | awk -F' |\r' '/^.ocation: /{print $2}' | tail -1)

			LATEST_VERSION=$(echo "$URL:t:r" | sed 's#.*1Password-##g' )
		fi
	fi
}


        # if the user explicitly askes for version 6, use it, regardless of the above
if [ "$1" = "--use6" -o "$1" = "-6" ]
then
	use_v6
elif [ "$1" = "--use7" -o "$1" = "-7" ]
then
	use_v7
else
	if [ -e "$V6_INSTALL_TO" -a -e "$V7_INSTALL_TO" ]
	then
		# Technically this should never happen, as the installers for v6 and v7 will remove the other version
		# if found during installation. But if it _does_ happen, we should be ready for it.
			echo "$NAME: Both versions 6 and 7 of 1Password are installed. I will _only_ check for updates for version 7 in this situation."
			echo "  If you want to check for updates for version 6, add the argument '--use6' i.e. '$0:t --use6' "
			echo "  To avoid this message in the future, add the argument '--use7' i.e. '$0:t --use7' "

			use_v7

	elif [ ! -e "$V6_INSTALL_TO" -a -e "$V7_INSTALL_TO" ]
	then
			# version 6 is not installed but version 7 is
		use_v7
	elif [ -e "$V6_INSTALL_TO" -a ! -e "$V7_INSTALL_TO" ]
	then
		# version 6 is installed but version 7 is not
		use_v6
	else
		# neither v6 or v7 are installed
		use_v7
	fi
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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."

		if [[ "$USE_VERSION" == "7" ]]
		then
			echo "	See <https://itunes.apple.com/us/app/1password-7-password-manager/id1333542190?mt=12> or"
			echo "	<macappstore://itunes.apple.com/us/app/1password-7-password-manager/id1333542190>"
		fi

		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else
	FIRST_INSTALL='yes'
fi

if [[ "$USE_VERSION" == "7" ]]
then
	if (( $+commands[lynx] ))
	then

		if [ "$BETAS" = 'yes' ]
		then

			RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

			echo -n "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION)"

			curl -sfL "$RELEASE_NOTES_URL" \
				| sed "1,/class='beta'/d; /<article /,\$d" \
				| sed '1,/<\/h3>/d' \
				| lynx -dump -nomargins -width='100' -assume_charset=UTF-8 -pseudo_inlines -stdin

			echo "\nSource: <$RELEASE_NOTES_URL>"

		else

			RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

			echo -n "$NAME: Release Notes for $INSTALL_TO:t:r"

			curl -sfL "$RELEASE_NOTES_URL" \
			| sed '1,/<article id="v[0-9]*"[ ]*>/d; /<\/article>/,$d' \
			| egrep -vi 'never prompts you for a review|If you need us, you can find us at|<a href="https://c.1password.com/dist/1P/mac7/.*">download</a>' \
			| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin \
			| sed '/./,/^$/!d'
			# sed delete blank lines at start of file

			echo "\nSource: <$RELEASE_NOTES_URL>"
		fi

	fi
fi

FILENAME="$HOME/Downloads/1Password-${LATEST_VERSION}.pkg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$FILENAME"
else
		##
		## The requirement for 'sudo' means that this script can't be run unattended, which stinks.
		## If 'sudo 'fails for some reason, we'll just show the .pkg file to the user
		##

	sudo /usr/sbin/installer -pkg "$FILENAME" -target / -lang en 2>&1 \
	|| open -R "$FILENAME"

fi

exit 0
#EOF
