
The purpose of `com.tjluoma.di-auto.sh` is to create a `launchd` plist which will run [di-auto.sh --update](https://github.com/tjluoma/di/blob/master/di-auto.sh) once a day, which will automatically look for all updates using the `di-` scripts, but only for apps which are already installed.

The easiest way to install this is to copy/paste this into Terminal.app:

	/bin/zsh -c "$(curl -sfL https://raw.githubusercontent.com/tjluoma/di/master/launchd/com.tjluoma.di-auto.sh)"

That will create and load the launchd plist for you.

See [com.tjluoma.di-auto.sh](https://github.com/tjluoma/di/blob/master/launchd/com.tjluoma.di-auto.sh) for more details.
