require 'rss/2.0'
require 'net/https'

class ProcessNewArticlesJob < Struct.new(:rss_feed, :settings)
  def perform
    content = ''

    # support basic auth over ssl
    connection = rss_feed['connection']

    if connection['auth']
      content = fetch_rss_over_auth(rss_feed)
    else
      open(rss_feed['connection']) do |s|
        content = s.read
      end
    end

    # parse
    feed = RSS::Parser.parse(content, false)

    # all articles previously fetched
    feed_articles = Article.where(:feed_url => feed.channel.link)
    first_fetch = !feed_articles.any?

    # insert unique items into mongo
    feed.items.each do |item|
      item_hash = Hash.from_xml(item.to_s)['item']
      item_hash['feed_url'] = feed.channel.link

      # collection could change in the loop
      unless Article.where(:feed_url => feed.channel.link, :link => item_hash['link']).any?

        if !first_fetch || (first_fetch && settings['process_on_start'])
          call_webhook(item_hash, rss_feed)
        end

        # assume that items with different URLs are different
        article = Article.new(item_hash)
        article.save!
      end
    end

    schedule_next(settings['check_interval'])
  end

  private

  def fetch_rss_over_auth(rss_feed)
    connection = rss_feed['connection']
    port = 80

    if connection['ssl']
      port = 443
    end

    content = href = ''
    begin
      http = Net::HTTP.new(connection['host'], port)
      http.use_ssl = connection['ssl']

      http.start do |http|
        req = Net::HTTP::Get.new(connection['resource'])
        req.basic_auth(connection['auth']['username'], connection['auth']['password'])

        response = http.request(req)
        content = response.body
      end
    end

    content
  end

  def call_webhook(article_hash, rss_feed)
    webhook = rss_feed['webhook']
    output_settings = nil

    if rss_feed['output']
      Marshal.load(Marshal.dump(rss_feed['output'])) # don't change the original
    end

    output_hash = Hash.new

    if output_settings
      # replace any placeholders
      interpolate_output_with_values(output_settings, article_hash)
      output_hash = output_settings
    else
      output_hash['article'] = article_hash.to_json
    end

    # post/get the request
    request_type = rss_feed['type']
    begin
      if request_type && request_type == 'get'
        RestClient.get webhook, output_hash
      else
        RestClient.post webhook, output_hash
      end
    rescue => e
      e.response
    end
  end

  def interpolate_output_with_values(node, article_hash)
    node.each do |k, v|
      if v.is_a? Hash
        interpolate_output_with_values(v, article_hash)
      else
        if v.is_a? String
          regex = /\|([A-Za-z0-9_]+)\|/i
          matches = regex.match v

          if matches
            node[k] = v.gsub(regex) do |s|
              eval "article_hash['#{$1}']"
            end
          end
        end
      end
    end
  end

  def schedule_next(check_interval)
    Delayed::Job.enqueue self, 0, Time.now + check_interval
  end
end