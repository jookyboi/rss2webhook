class Article
  include MongoMapper::Document

  # Written according to RSS 2.0 specs: http://cyber.law.harvard.edu/rss/rss.html

  # required
  key :title, String, :required => true
  key :link, String, :required => true
  key :description, String, :required => true

  # optional
  key :language, String
  key :copyright, String
  key :managingEditor, String
  key :webMaster, String
  key :pubDate, String
  key :lastBuildDate, Date
  key :category, String
  key :generator, String
  key :docs, String
  key :cloud, String
  key :ttl, Integer
  key :image, String
  key :rating, String
  key :textInput, String
  key :skipHours, Array
  key :skipDays, Array

  timestamps!
end