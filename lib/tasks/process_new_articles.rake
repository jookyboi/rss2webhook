require_relative '../delayed_jobs/process_new_articles_job'

desc 'Start processing new rss feed articles'
task :process_new_articles => :environment do
  config = RSS_CONFIG
  feeds = config['rss_feeds']

  feeds.each do |feed|
    Delayed::Job.enqueue ProcessNewArticlesJob.new(feed, config['settings'])
  end
end