web: bundle exec rails server -p $PORT thin -e $RACK_ENV
worker: bundle exec rake jobs:work
start: bundle exec rake process_new_articles