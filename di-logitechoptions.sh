#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-02-28

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi


URL=$(curl -sfLS "https://www.logitech.com/en-us/product/options"| tr '"' '\012' | egrep 'http.*\.zip')

# https://download01.logi.com/web/ftp/pub/techsupport/options/Options_8.10.64.zip


exit 0
#EOF
