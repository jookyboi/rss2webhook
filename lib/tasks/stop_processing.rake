desc 'Stop processing new rss articles'
task :stop_processing => :environment do
  Delayed::Job.all.each do |dj|
    dj.delete
  end
end