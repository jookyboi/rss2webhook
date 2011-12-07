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

rss2webhook was made to be deployed easily on Heroku. You can however, tweak it to
deploy on any server with a SQL-DB backing and MongoDB support.

## Deploying rss2webhook

Below are instructions for deploying rss2webhook on Heroku.

### Clone this repo

    git clone git@github.com:jookyboi/rss2webhook.git

### Bundle the gems

    bundle install

### Migrate database

    rake db:migrate

### Configure the Postgres database

All database configuration is in ``database.yml``. Change it to suit your environment.

### Configure MongoMapper

rss2webhook uses MongoMapper as an adapter for MongoDB. If you are testing the app out
in your local environment and you already have MongoDB running, the first condition
in ``config/initializers/mongo.rb`` should have you covered.

If you are deploying to Heroku, you'll need to first sign up for either a [MongoLab](http://addons.heroku.com/mongolab)
or [MongoHQ](http://addons.heroku.com/mongohq) account. (I personally use MongoLab as their
free plan comes with a generous 240MB of space.) In ``mongo.rb``, uncomment one of the 2 configuration
lines to work with your MongoDB provider.

```ruby
MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOLAB_URI']} }
```

or for MongoHQ:

```ruby
MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOHQ_URL']} }
```

### Configure your RSS feeds and webhooks

Open up ``config/config.yml``, the central [YAML](http://www.yaml.org/) file for configuring
rss2webhook.

You'll need to start by adding a section for ``production:`` and a few global settings:


```yaml
production:
  settings:
    type: post  # either post or get
    process_on_start: false  # whether to send all the articles on first fetch of the feed
    check_interval: 10  # check for feed updates every x seconds
```

After that, you need to configure at least one RSS feed and its corresponding webhook. Here is
an example for an unauthenticated RSS sample feed from [SilverOrange](http://labs.silverorange.com/archive/2003/july/privaterss)
sending data to a HipChat room webhook ([message API](https://www.hipchat.com/docs/api/method/rooms/message)).

```yaml
  rss_feeds:
    -
      connection: http://labs.silverorange.com/local/solabs/rsstest/rss_plain.xml
      webhook: https://api.hipchat.com/v1/rooms/message  # any web url
      type: get  # can be get or post
      output:
        auth_token: 37b6805ad9ef28b523268053d5953c
        room_id: 48856
        from: |author|  # equivalent to rss_article['author']
        message: |title| at |link|  # interpolated values of rss_article
        format: json
```

See the configuration examples below for info on dealing with basic authentication, SSL,
and different output formats.

### Test it out locally

### Deploy on Heroku

## Configuration Examples

Below are a few configurations for popular web services that support webhooks.

## Advanced Usage