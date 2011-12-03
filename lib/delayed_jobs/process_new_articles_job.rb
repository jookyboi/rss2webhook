require 'rss/2.0'

class ProcessNewArticlesJob < Struct.new(:rss_feed, :settings)
  def perform
    content = ''

    open(rss_feed['url']) do |s|
      content = s.read
    end

    feed = RSS::Parser.parse(content, false)

    # assume that items with different URLs are different
    feed.items.each do |item|
      
    end
  end
end