require 'rss/2.0'

class ProcessNewArticlesJob < Struct.new(:rss_feed_url)
  def perform
    
  end
end