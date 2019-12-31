#!/bin/zsh -f
# Purpose: Download and install the latest version of TeXShop from http://pages.uoregon.edu/koch/texshop/
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19

NAME="$0:t:r"

INSTALL_TO="/Applications/TeX/TeXShop.app"

XML_FEED="http://pages.uoregon.edu/koch/texshop/texshop-64/texshopappcast.xml"

HOMEPAGE="http://pages.uoregon.edu/koch/texshop/"

DOWNLOAD_PAGE="https://pages.uoregon.edu/koch/texshop/texshop-64/texshop.zip"

SUMMARY="TeXShop is a TeX previewer for Mac OS X, written in Cocoa. Since pdf is a native file format on OS X, TeXShop uses 'pdftex' and 'pdflatex' rather than 'tex' and 'latex' to typeset in its default configuration; these programs in the standard TeX Live distribution of TeX produce pdf output instead of dvi output."

if [ -e "$HOME/.path" ]
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

	# Since this is eventually installed into a non-standard directory
	# '/Applications/TeX/' not just '/Applications/'
	# we need to make sure that it exists.
	# Now, normally we could use 'ditto' to make the directory, but
	# we have ditto unzip to a temp directory and then move the old app aside
	# (if one exists). This has the benefit of meaning that if we have an old
	# version and the new one fails to unzip (via ditto) for some reason,
	# we will still have the old version. Life is a series of trade-offs.
if [[ ! -d "$INSTALL_TO:h" ]]
then
	mkdir -p "$INSTALL_TO:h" || die "Failed to create '$INSTALL_TO:h'!"
fi

	# sparkle:version= is the only version information in the feed,
	# CFBundleShortVersionString and CFBundleVersion are identical in the app itself
INFO=($(curl -sfL $XML_FEED \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:version)=' \
		| head -2 \
		| sort \
		| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| sed '1,/<sparkle:releaseNotesLink>/d; /<\/sparkle:releaseNotesLink>/,$d ; s#.*http#http#g')

	if [[ "$RELEASE_NOTES_URL" == "" ]]
	then

		echo "No Release Notes found" | tee "$FILENAME:r.txt"

	else

		( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n" ;
			curl -sfL $RELEASE_NOTES_URL \
			| sed '1,/<h3>/d; /<h3>/,$d' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"
	fi
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$INSTALL_TO:h/.Trashes/$UID/\"."

	mv -vf "$INSTALL_TO" "$INSTALL_TO:h/.Trashes/$UID/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $INSTALL_TO:h/.Trashes/$UID/"

		exit 1
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

exit 0
EOF
