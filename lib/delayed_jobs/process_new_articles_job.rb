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

        if !first_fetch || (first_fetch && settings['process_on_start'])
          post_to_webhook(item_hash.to_json, rss_feed['webhook'])
        end

        # assume that items with different URLs are different
        article = Article.new(item_hash)
        article.save!
      end
      
    end

    schedule_next(settings['check_interval'])
  end

  def post_to_webhook(item_json, webhook_url)
    begin
      response = RestClient.post webhook_url, :article => item_json
    rescue => e
      e.response
    end
  end

  def schedule_next(check_interval)
    Delayed::Job.enqueue self, 0, Time.now + check_interval
  end
end