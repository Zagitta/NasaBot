require 'json'
require 'net/http'

class Stream
    
  def initialize(channel)
    @channel = channel
    @viewers = viewers(channel)
    @chatters = chatters(channel)
    @followers = followers(channel)
    @featured = featured?(channel)
  end
  
  def featured?(channel)
    request = Net::HTTP.get(URI.parse("https://api.twitch.tv/kraken/streams/featured"))
    streams = JSON.parse(request, {symbolize_names: true })[:featured]
    streams.each do |stream|
      return true if stream[:stream][:channel][:name] == channel
      
    end
    return false
  end
  
  def viewers(channel)
    request = Net::HTTP.get(URI.parse("https://api.twitch.tv/kraken/streams/#{channel}"))
    count = JSON.parse(request, {symbolize_names: true })[:stream][:viewers]
    return count
  end
  
  def chatters(channel)
    request = Net::HTTP.get(URI.parse("http://tmi.twitch.tv/group/user/#{channel}"))
    count = JSON.parse(request, {symbolize_names: true })[:chatter_count]
    return count
  end
  
  def followers(channel)
    request = Net::HTTP.get(URI.parse("https://api.twitch.tv/kraken/channels/#{channel}"))
    count = JSON.parse(request, {symbolize_names: true })[:followers]
    return count
  end
  
  def ratio_chatters_viewers
    return (@chatters.to_f/@viewers.to_f).round(3)
  end
  
  def ratio_viewers_followers
    return (@viewers.to_f/@followers.to_f).round(3)
  end
  
  def viewbot
    cv_pr = cv_probability.to_f
    vf_pr = vf_probability.to_f
    uc_fac = 1 - uncertainty
    return ((cv_pr+vf_pr)/2).round(3) * ((cv_pr == 1 && vf_pr == 1) ? 1 : uc_fac)
  end
  
  def uncertainty
    return 0.6 if @featured
    
    return 0
  end
  
  def cv_probability
    ratio = ratio_chatters_viewers
    return 1 if ratio < 0.16
    return (0.55-ratio).abs
  end
  
  def vf_probability
    ratio = ratio_viewers_followers
    return 1 if ratio >= 1
    return 0 if ratio < 0.2
    return ratio * 0.8
  end
  
  def is_featured?
    return @featured
  end
end

class Viewbot < Plugin
  def viewbot(user, args)
    channel = args.strip.downcase
    begin
      stream = Stream.new(channel)
      cv = stream.ratio_chatters_viewers
      vf = stream.ratio_viewers_followers
      vbot = stream.viewbot
      
      message = "does not have a viewbot running"
      
      if vbot == 1
        message = "definitely has a viewbot running"
      elsif vbot >= 0.5
        message = "seems to have a viewbot running"
      elsif vbot >= 0.2
        message = "might have a viewbot running"
      end
      @bot.say("twitch.tv/#{channel} #{message}.")
    rescue
      @bot.say("Stream not found or offline.")
    end   
  end
  
  def register_functions
    register_command('viewbot', USER::ALL, 'viewbot')
  end
end