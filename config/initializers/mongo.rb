if Rails.env == 'development' || Rails.env == 'test'

  MongoMapper.database = "rss2webhook_#{Rails.env}"

elsif Rails.env == 'production'

end
