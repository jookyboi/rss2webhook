require 'rss/2.0'

class ProcessNewArticlesJob < Struct.new(:rss_feed, :settings)
  def perform
    content = ''

    open(rss_feed['url']) do |s|
      content = s.read
    end

    feed = RSS::Parser.parse(content, false)

    # all articles previously fetched
    feed_articles = Article.where(:feed_url => feed.channel.link)
    first_fetch = !feed_articles.any?

    # insert unique items into mongo
    feed.items.each do |item|
      item_hash = Hash.from_xml(item.to_s)['item']
      item_hash['feed_url'] = feed.channel.link

      unless feed_articles.where(:link => item_hash['link']).any?
        puts item_hash['link']

        # assume that items with different URLs are different
        article = Article.new(item_hash)
        article.save!
      end
    end

    schedule_next(settings['check_interval'])
  end

  def schedule_next(check_interval)
    Delayed::Job.enqueue self, 0, Time.now + check_interval
  end
end