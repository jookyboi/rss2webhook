if Rails.env == 'development' || Rails.env == 'test'

  MongoMapper.database = "rss2webhook_#{Rails.env}"

elsif Rails.env == 'production'

  # Example MongoLab settings for Heroku
  #MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOLAB_URI']} }

  # Example MongoHQ settings for Heroku
  #MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOHQ_URL']} }

  #MongoMapper.connect(Rails.env)
end
