# rss2webhook - Send RSS feed articles to any webhook

rss2webhook is a barebones Rails app made to fetch new articles from an arbitrary
RSS feed and POST (or GET) them to user-specified webhooks. It easily handles both plain
and authenticated RSS feeds over http/https.

The vast majority of the app's functionality can be configured through one YAML
configuration file: ``config.yml``. RSS feeds are set up here with a URL and authentication
options. The webhook can be configured to either POST or GET a custom JSON object.
The JSON data to be sent is configurable to be any tree structure you like.
``|pipes|`` are used to inject RSS item attributes into the JSON. See the examples
below for details.