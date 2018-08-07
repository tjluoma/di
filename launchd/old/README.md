The file `com.tjluoma.di-all.plist` must be installed at `$HOME/Library/LaunchAgents` where "$HOME" stands for your home directory, such as 

	/Users/JSmith/Library/LaunchAgents/com.tjluoma.di-all.plist
	
To load it, you either have to a) log out and log in again, or b) use Terminal:
	
	launchctl load $HOME/Library/LaunchAgents/com.tjluoma.di-all.plist
	
## Command-line Installation 

	mkdir -p "$HOME/Library/LaunchAgents/"
	
	cd "$HOME/Library/LaunchAgents/"

	curl --remote-name https://raw.githubusercontent.com/tjluoma/di/master/launchd/com.tjluoma.di-all.plist
	
	launchctl load $PWD/com.tjluoma.di-all.plist

