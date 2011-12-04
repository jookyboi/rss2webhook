desc 'Stop processing new rss articles'
task :stop_processing_articles => :environment do
  Delayed::Job.all.each do |dj|
    dj.delete
  end
end