class Butts < Plugin
  def initialize(bot)
    super(bot)
    @database = open_database("butts")
    @database.execute("CREATE TABLE IF NOT EXISTS 'butts' (hash TEXT PRIMARY KEY, title TEXT);")    
  end
  
  def butt(user, args)
    butts = @database.execute("SELECT hash FROM butts ORDER BY RANDOM() LIMIT 1;")
    return if butts.nil?
    butt = butts.first["hash"]
    @bot.say("http://imgur.com/#{butt}")
  end
  
  def register_functions
    register_command('butt', USER::ALL, 'ilikeclouds')
  end
  
end