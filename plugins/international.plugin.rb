require 'net/http'

class International < Plugin
  
  def initialize(bot)
    super(bot)
    @APIKEY = CONFIG::STEAM_KEY
    @LEAGUEID = 600
    @URL = URI.parse("http://api.steampowered.com/IEconDOTA2_570/GetTournamentPrizePool/v1?key=#{@APIKEY}&leagueid=#{@LEAGUEID}")
  end
  
  def pricepool(user, args)
    result = Net::HTTP.get(@URL)
    data = JSON.parse(result, { symbolize_names: true })[:result]
    num = data[:prize_pool]
    num = num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    @bot.say("TI4 PRIZE POOL: $#{num}", @bot.user_mod?(user))
  end
  
  def gpm(user, args) # Credits to Pozzuh
    beginTime = 1399701600 #2014-05-10 08:00:00 +0200
    difTimeMin = (Time.now.to_i - beginTime) / 60
    
    stringMoney = Net::HTTP.get(URI.parse('http://dota2.cyborgmatt.com/prizetracker/overlay.php?leagueid=600'))
    intMoney = stringMoney.to_i - 1600000 # base prize pool
    
    gpmRaised = intMoney / difTimeMin
    gpmForGabe = gpmRaised * 3 #volvo gets 3/4th 
    
    @bot.say("Prize pool gpm: #{gpmRaised}, money for GabeN gpm: #{gpmForGabe}.")
  end
  
  def register_functions
    register_command('pricepool', USER::ALL, 'ti4')
    register_command('gpm', USER::ALL, 'gpm')
  end
end