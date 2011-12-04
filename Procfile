web: bundle exec rails server -p $PORT thin -e $RACK_ENV
worker: bundle exec rake jobs:work
start: bundle exec rake start_processing_articles
stop: bundle exec rake stop_processing_articles