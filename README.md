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

### Step 1: Clone this repo

    git clone git://github.com/jookyboi/rss2webhook.git

### Step 2: Bundle the gems

    bundle install

### Step 3: Configure the Postgres database

All database configuration is in ``config/database.yml``. Change it to suit your environment.

### Step 4: Create and Migrate database

    rake db:create
    rake db:migrate

### Step 5: Configure MongoMapper

rss2webhook uses MongoMapper as an adapter for MongoDB. If you are testing the app out
in your local environment and you already have MongoDB running, the first condition
in ``config/initializers/mongo.rb`` should have you covered. If you don't have MongoDB installed,
download the appropriate distro [here](http://www.mongodb.org/downloads).

If you are deploying to Heroku, you'll need to sign up for either a [MongoLab](http://addons.heroku.com/mongolab)
or [MongoHQ](http://addons.heroku.com/mongohq) account after deploying. (I personally use MongoLab as their
free plan comes with a generous 240MB of space.) In ``mongo.rb``, uncomment one of the 2 configuration
lines to work with your MongoDB provider.

```ruby
MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOLAB_URI']} }
```

or for MongoHQ:

```ruby
MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOHQ_URL']} }
```

### Step 6: Configure your RSS feeds and webhooks

Open up ``config/config.yml``, the central [YAML](http://www.yaml.org/) file for configuring
rss2webhook.

You'll need to start by adding sections for ``development:`` and ``production:``. For each section,
define a set of global settings. Below is an example of one section for ``production``. Be sure to
do something similar for ``development`` so you can test locally.

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

### Step 7: Test it out locally

rss2webhook provides you with a few rake scripts to start, stop, and restart the RSS feed processing.
Under the hood, they insert and delete delayed jobs.

Assumbing your Mongo and DJ configuration is correct, you can insert the DJ for processing feeds with:

    rake start_processing

Next, use [Foreman](http://michaelvanrooijen.com/articles/2011/06/08-managing-and-monitoring-your-ruby-application-with-foreman-and-upstart/)
to spin up a worker:

    foreman start worker

Assuming things are working, you should see the DJ fire once every few seconds for each one of the configured feeds.

### Step 8: Deploy on Heroku

You are now ready to deploy on Heroku. Due to rss2webhook's reliance on a Procfile and Rails 3.1, it is
recommended you use the [Cedar](http://devcenter.heroku.com/articles/cedar#using_cedar) stack.

First, commit your changes:

    git commit -am "Changed configuration for deployment"

In the project directory, type:

    heroku create --stack cedar

Push your repo to Heroku:

    git push heroku master

You'll need an instance of a MongoDB running. I recommend MongoLab. Their starter plan is free:

    heroku addons:add mongolab:starter

Next, migrate the database:

    heroku run rake db:migrate

Make sure you scale down the web worker (there is no frontend) and scale up the background worker:

    heroku scale web=0
    heroku scale worker=1

Lastly, to kick everything off, run the rake task:

    heroku run rake start_processing

Tail the logs just to make sure things are going as expected:

    heroku logs --tail

That's it! You should now have an instance of rss2webhook sending RSS articles to webhooks.

## Configuration Examples

Below are a few typical configurations.

### RSS over no-auth HTTP, simple POST to webhook

```yaml
  -
    connection: http://www.example.com/rss.xml
    webhook: http://www.chatroom.com/webhook  # POSTs article => { link => ... }
```

### RSS over basic-auth HTTP, simple POST to webhook

```yaml
  -
    connection:
      host: basicauth.example.com
      ssl: false
      resource: /feeds/daily
      auth:
        username: basicauth_user
        password: my_password
    webhook: http://www.chatroom.com/webhook
```

## Advanced Usage