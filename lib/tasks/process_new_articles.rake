require_relative '../delayed_jobs/process_new_articles_job'

desc 'Start processing new rss feed articles'
task :process_new_articles, :rss_feed_url, :needs => :environment do |t, args|
  Delayed::Job.enqueue ProcessNewArticlesJob.new(args[:rss_feed_url])
end
