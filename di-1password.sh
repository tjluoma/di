#!/bin/zsh -f
# Purpose: Download 1Password 6 or 7 depending on OS version or what's already installed
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

NAME="$0:t:r"

HOMEPAGE="https://1password.com"

DOWNLOAD_PAGE="https://1password.com/downloads/"

SUMMARY="Go ahead. Forget your passwords. 1Password remembers them all for you. Save your passwords and log in to sites with a single click. It's that simple."

URL=$(curl -sfLS --head 'https://app-updates.agilebits.com/download/OPM7' | awk -F' |\r' '/^.ocation:/{print $2}')

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_V6_TO='/Applications/1Password 6.app'
INSTALL_V7_TO='/Applications/1Password 7.app'

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

	if [[ -e "$INSTALL_V7_TO" ]]
	then
		echo "$NAME: $INSTALL_V7_TO is installed. Cannot have both installed at the same time. To install 1Password 6, please remove 1Password 7."
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

			# if we find the old prefer-beta file, move it to the new place
		OLD_PREFERS_BETAS_FILE="$HOME/.config/di/1Password-prefer-betas.txt"
		PREFERS_BETAS_FILE="$HOME/.config/di/prefers/1Password-prefer-betas.txt"

		[[ ! -d "$PREFERS_BETAS_FILE:h" ]] && mkdir "$PREFERS_BETAS_FILE:h"

		if [[ -e "$OLD_PREFERS_BETAS_FILE" ]]
		then
			if [[ -e "$PREFERS_BETAS_FILE" ]]
			then
					# if the new betas file exists, just delete the old one
				rm -f "$OLD_PREFERS_BETAS_FILE"
			else
					# if the new betas file does NOT exist, move the old one to the new place.
				mv -vf "$OLD_PREFERS_BETAS_FILE" "$PREFERS_BETAS_FILE"
			fi
		fi

		if [[ -e "$INSTALL_TO" ]]
		then
			INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

			INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)
		else

			INSTALLED_BUILD='70000000'
		fi

		DARWIN_VERSION=$(uname -r)

		CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString)

		if [[ -e "$PREFERS_BETAS_FILE" ]]
		then
				# This is for betas
			FEED_URL="https://app-updates.agilebits.com/check/1/${DARWIN_VERSION}/OPM7/en/${INSTALLED_BUILD}/YES"
			NAME="$NAME (beta releases)"

		else
				# This is for non-beta releases
			FEED_URL="https://app-updates.agilebits.com/check/1/${DARWIN_VERSION}/OPM7/en/${INSTALLED_BUILD}"
		fi

		ALL_INFO=($(curl -sS --location "$FEED_URL" \
			-H "Accept: */*" \
			-H "Accept-Language: en-us" \
			-H "User-Agent: 1Password%20Updater/${INSTALLED_BUILD} CFNetwork/${CFNETWORK_VER} Darwin/${DARWIN_VERSION} (x86_64)"))

		if [[ "$ALL_INFO" == '{"available":"0"}' ]]
		then
			echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
			exit 0
		fi

		INFO=($(echo "$ALL_INFO" \
			| tr '{|}|,|\[|\]' '\012' \
			| tr '"' ' ' \
			| egrep '^ (version|relnotes|url) : ' \
			| head -3 \
			| sort))

		RELEASE_NOTES_URL="$INFO[3]"

		URL="$INFO[6]"

		LATEST_VERSION="$INFO[9]"

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
	if [ -e "$INSTALL_V6_TO" -a -e "$INSTALL_V7_TO" ]
	then
		# Technically this should never happen, as the installers for v6 and v7 will remove the other version
		# if found during installation. But if it _does_ happen, we should be ready for it.
			echo "$NAME: Both versions 6 and 7 of 1Password are installed. I will _only_ check for updates for version 7 in this situation."
			echo "  If you want to check for updates for version 6, add the argument '--use6' i.e. '$0:t --use6' "
			echo "  To avoid this message in the future, add the argument '--use7' i.e. '$0:t --use7' "

			use_v7

	elif [ ! -e "$INSTALL_V6_TO" -a -e "$INSTALL_V7_TO" ]
	then
			# version 6 is not installed but version 7 is
		use_v7
	elif [ -e "$INSTALL_V6_TO" -a ! -e "$INSTALL_V7_TO" ]
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

URL_EXTENSION="$URL:e:l"

if [ "$URL_EXTENSION" = "pkg" ]
then

	FILENAME="$HOME/Downloads/1Password-${LATEST_VERSION}.pkg"

elif [ "$URL_EXTENSION" = "zip" ]
then
	FILENAME="$HOME/Downloads/1Password-${LATEST_VERSION}.zip"
else
	echo "$NAME: Don't know what to do with URLs that end with '$URL_EXTENSION'. Can't download '$URL'."
	exit 1
fi

if [[ "$USE_VERSION" == "7" ]]
then
	if (( $+commands[lynx] ))
	then

		if [ "$BETAS" = 'yes' ]
		then

			RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

			( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION)" ;
			curl -sfL "$RELEASE_NOTES_URL" \
				| sed "1,/class='beta'/d; /<article /,\$d" \
				| sed '1,/<\/h3>/d' \
				| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nolist -nonumbers -stdin ;
			echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

		else

			RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

			( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r" ;
			curl -sfL "$RELEASE_NOTES_URL" \
			| sed '1,/<article id="v[0-9]*"[ ]*>/d; /<\/article>/,$d' \
			| egrep -vi 'never prompts you for a review|If you need us, you can find us at|<a href="https://c.1password.com/dist/1P/mac7/.*">download</a>' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nolist -nonumbers -stdin \
			| sed '/./,/^$/!d' ;
			echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

		fi

	fi
fi


echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ "$URL_EXTENSION" == "pkg" ]]
then

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

else

	# if we get here, it must be a .zip file

	UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

	echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

	ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

	EXIT="$?"

	if [[ "$EXIT" == "0" ]]
	then
		echo "$NAME: Unzip successful"
	else
			# failed
		echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

		exit 1
	fi

	if [[ -e "$INSTALL_TO" ]]
	then

		pgrep -xq "$INSTALL_TO:t:r" \
		&& LAUNCH='yes' \
		&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

		mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

		EXIT="$?"

		if [[ "$EXIT" != "0" ]]
		then

			echo "$NAME: failed to move existing '$INSTALL_TO' to $HOME/.Trash/"

			read -t 30 "?Do you want to use ’sudo’ to try to move the outdated ‘$INSTALL_TO’? [y/N] " ANSWER

			case "$ANSWER" in

				Y*|y*)
						sudo mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

						EXIT="$?"

						if [ "$EXIT" = "0" ]
						then
							echo "$NAME: Successfully moved outdated '$INSTALL_TO' to the trash."

						else
							echo "$NAME: failed to move outdated '$INSTALL_TO' to the trash. Giving up."

							exit 1
						fi

				;;

				*)
						echo "$NAME: Ok, not using 'sudo'. Giving up now."
						exit 1
				;;

			esac

		fi
	fi

	echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

		# Move the file out of the folder
	mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

	EXIT="$?"

	if [[ "$EXIT" = "0" ]]
	then

		echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	else
		echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

		exit 1
	fi

	[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

fi

exit 0
#EOF
