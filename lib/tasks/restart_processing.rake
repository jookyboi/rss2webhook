desc 'Restart processing new rss articles'
task :restart_processing => :environment do
  # stop
  Delayed::Job.all.each do |dj|
    dj.delete
  end

  #start
  config = RSS_CONFIG
  feeds = config['rss_feeds']

  feeds.each do |feed|
    Delayed::Job.enqueue ProcessNewArticlesJob.new(feed, config['settings'])
  end
end