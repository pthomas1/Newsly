# Newsly
App experimenting with the newsapi.org API

# Build
The project uses cocoapods so be sure to run pod install. You should also use the workspace and not the project file for editing in Xcode. In order to run the app you must get an API key from newsapi.org and add a file called Keys.plist with a string key newsAPIKey set to your API key.

# Overview
The app presents content from the newsapi.org API. The user can specify which news sources he is interested in viewing. The app then displays a simple list of news stories sorted by publication date.