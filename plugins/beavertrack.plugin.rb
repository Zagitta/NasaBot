require 'twitter'

class Beavertrack < Plugin
  
  def initialize(bot)
    super(bot)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = CONFIG::TWITTER_CONSUMER_KEY
      config.consumer_secret = CONFIG::TWITTER_CONSUMER_SECRET
      config.access_token = CONFIG::TWITTER_ACCESS_TOKEN
      config.access_token_secret = CONFIG::TWITTER_ACCESS_SECRET
    end
  end
  
  def twitter(user, args)
    last_tweet = @client.user_timeline("sing2x", { count: 1, exclude_replies: true })[0]
    tweet = last_tweet.to_h
    date = tweet[:created_at][/[a-zA-z]{3}\s[0-9]{2}/]
    @bot.say("#{tweet[:user][:name]} @#{tweet[:user][:screen_name]} - #{date} #{last_tweet.full_text.gsub(/\n/, '')}")
  end
  
  def register_functions
    register_command('twitter')
  end
end