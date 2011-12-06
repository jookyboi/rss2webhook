desc 'Start processing new rss feed articles'
task :start_processing => :environment do
  config = RSS_CONFIG
  feeds = config['rss_feeds']

  feeds.each do |feed|
    Delayed::Job.enqueue ProcessNewArticlesJob.new(feed, config['settings'])
  end
end
