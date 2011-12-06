require 'spec_helper'

describe ProcessNewArticlesJob do
  before(:each) do
    Article.all.each do |a|
      a.delete
    end
  end

  it 'should process simple unauthenticated rss' do
    config = RSS_CONFIG
    feeds = config['rss_feeds']

    enqueue_process(feeds[0], config['settings'])
    work_off

    item = Article.where(:link => 'http://labs.silverorange.com/archives/2003/june/canyousaythat')
    item.any?.should be(true)
    item.size.should be(1)

    Article.all.size.should be(6)
  end
end

private

def enqueue_process(rss_feed, settings)
  Delayed::Job.enqueue ProcessNewArticlesJob.new(rss_feed, settings)
end

def work_off
  Delayed::Worker.new.work_off
end