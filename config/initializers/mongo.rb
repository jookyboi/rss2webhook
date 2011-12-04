if Rails.env == 'development'

  MongoMapper.database = "rss2webhook_#{Rails.env}"

elsif Rails.env == 'production'

end
