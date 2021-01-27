#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-01-27

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

#   homepage "https://www.barebones.com/products/yojimbo/"

INSTALL_TO='/Applications/Yojimbo.app'

XML_FEED="https://versioncheck.barebones.com/Yojimbo.xml"

#   url "https://s3.amazonaws.com/BBSW-download/Yojimbo_#{version}.dmg",
#       verified: "s3.amazonaws.com/BBSW-download/"


zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS")

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

TEMPFILE="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.plist"

cat <<EOINPUT > $TEMPFILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
EOINPUT

curl -sfLS "$XML_FEED" | awk '/<dict>/{i++}i==6' | sed '/<\/array>/,$d' >> "$TEMPFILE"

echo '</plist>' >> "$TEMPFILE"

echo "$TEMPFILE"

LATEST_VERSION=$(defaults read "$TEMPFILE" SUFeedEntryShortVersionString)
# 4.6.1

LATEST_BUILD=$(defaults read "$TEMPFILE" SUFeedEntryVersion)

URL=$(defaults read "$TEMPFILE" SUFeedEntryDownloadURL)

if (( $+commands[html2text.py] ))
then

	RELEASE_NOTES=$(sed '/<\/data>/,$d' "$TEMPFILE" \
			| sed -e '1,/<data>/d' -e 's#^\t*##g' \
			| base64 --decode \
			| textutil -convert html -stdin -stdout \
			| html2text.py \
			| sed 's#^ *##g' \
			| uniq)

fi



exit 0
#EOF
