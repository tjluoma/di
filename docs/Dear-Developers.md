# Dear Mac Developers:

I started this project to make life easier for me, but I hope that it will also make life easier for your users too.

You can see the original [README](https://github.com/tjluoma/di/blob/master/README.md) for more details, but the short version of my story is this:

I dislike the Mac App Store restrictions and “fart-app pricing” mentality that it fosters in users.

I prefer buying directly from developers whenever possible.

I want a way to install _and update_ your apps as easily as possible, to facilitate my non-use of the Mac App Store.

I also want to share this way with others, for free.

## How I do this 

I look for the URLs that you are already using to check for updates, and I write scripts that will check those URLs and compare them against already installed versions. 

If the app is not installed, the script installs it.

If the app is installed and up-to-date, it quits.

If the app is installed and out-of-date, it updates it silently, in the background, and hopefully the user never even knows it happened.

## Why I need your help

If you use [Sparkle](http://sparkle.andymatuschak.org/) and the URLs are in your `Info.plist`, I can probably find them myself. Otherwise I have been using [Charles Web Debugging Proxy](https://www.charlesproxy.com/) to try and suss them out.

However, sometimes I can’t do it without your help.

## “But what if I think this idea is stupid or I don’t want to help?”

That’s fine, I just will either not include your app, or look for another way (which usually involves scraping HTML, which is a terrible idea and error-prone, so I hate doing it).

## “OK, I’ll help.”

Great! Either send me the URLs directly or add them as [a new issue](https://github.com/tjluoma/di/issues/new) and I will integrate them.

You can email me at tj at luo dot ma or luomat @ gmail 
