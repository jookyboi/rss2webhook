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
          post_to_webhook(item_hash, rss_feed)
        end

        # assume that items with different URLs are different
        article = Article.new(item_hash)
        article.save!
      end

    end

    schedule_next(settings['check_interval'])
  end

  private

  def post_to_webhook(article, rss_feed)
    webhook = rss_feed['webhook']
    output_settings = rss_feed['output']
    output_hash = Hash.new

    if output_settings
      output_hash = interpolate_output_with_values(output_settings, article)
      puts output_hash
    else
      output_hash['article'] = article.to_json
    end

    begin
      RestClient.post webhook, output_hash
    rescue => e
      e.response
    end
  end

  def interpolate_output_with_values(output_settings, article)
    output_settings.each do |k, v|
      if v.is_a? Array
        v.each do |elm|
          interpolate_output_with_values(elm, article)
        end
      else
        if v.is_a? String
          regex = /{([A-Za-z0-9_]+)\}/i
          matches = regex.match v

          if matches
            output_settings[k] = v.gsub regex, "#{article[matches[1]]}"
          end
        end
      end
    end

    output_settings
  end

  def schedule_next(check_interval)
    Delayed::Job.enqueue self, 0, Time.now + check_interval
  end
end