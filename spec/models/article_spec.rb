require 'spec_helper'

describe Article do
  it 'should let a valid article be saved' do
    article = Article.new(
        {
            :title => 'My new article',
            :link => 'http://www.google.com',
            :description => 'Test article'
        }
    )

    article.save!
    article.should have(:no).errors
  end

  it 'should not let invalid articles be saved' do
    article = Article.new(
        {
            :link => 'http://www.google.com',
            :description => 'Test article'
        }
    )

    article.save
    article.should have(1).error_on(:title)

    article = Article.new
    article.save
    article.should have(1).error_on(:title)
    article.should have(1).error_on(:link)
    article.should have(1).error_on(:description)
  end
end