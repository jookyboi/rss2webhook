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
          make_request(item_hash, rss_feed)
        end

        # assume that items with different URLs are different
        article = Article.new(item_hash)
        article.save!
      end

    end

    schedule_next(settings['check_interval'])
  end

  private

  def make_request(article, rss_feed)
    webhook = rss_feed['webhook']
    output_settings = rss_feed['output']
    output_hash = Hash.new

    if output_settings
      # replace any placeholders
      output_hash = interpolate_output_with_values(output_settings, article)
    else
      output_hash['article'] = article.to_json
    end

    # post/get the request
    request_type = rss_feed['type']
    begin
      if request_type
        if request_type == 'get'
          RestClient.get webhook, output_hash
        else
          RestClient.post webhook, output_hash
        end
      else
        RestClient.post webhook, output_hash
      end
    rescue => e
      e.response
    end
  end

  def interpolate_output_with_values(node, article)
    node.each do |k, v|
      if v.is_a? Hash
        interpolate_output_with_values(v, article)
      else
        if v.is_a? String
          regex = /\{([A-Za-z0-9_]+)\}/i
          matches = regex.match v

          if matches
            node[k] = v.gsub regex, "#{article[matches[1]]}"
          end
        end
      end
    end

    node
  end

  def schedule_next(check_interval)
    Delayed::Job.enqueue self, 0, Time.now + check_interval
  end
end