require 'time'

class MMR < Plugin
  
  def initialize(bot)
    super(bot)
    @database = open_database("mmr")
    @database.execute("CREATE TABLE IF NOT EXISTS 'mmr' (solo TEXT, team TEXT, time TEXT);")
  end
  
  def mmr(user, args)
    data = @database.execute("SELECT solo, team FROM mmr ORDER BY time DESC LIMIT 1;")
    return @bot.say("Use !updatemmr to add your current MMR.") if data.nil?
    mmr = data[0]
    @bot.say("Solo MMR: #{mmr["solo"]}, Party MMR: #{mmr["team"]}.")
  end
  
  def update_mmr(user, args)
    mmr = args.strip.split(" ")
    time = Time.new
    return help if mmr.length != 2
    begin
      @database.execute("INSERT INTO mmr VALUES(?, ?, ?);", mmr[0], mmr[1], time.to_s)
      @bot.say("Updated MMR.", true)      
    end
  end
  
  def help
    @bot.say("Update your MMR with !updatemmr SOLO PARTY, example: !updatemmr 4000 3800.")
  end
  
  def register_functions
    register_command('mmr')
    register_command('update_mmr', USER::BROADCASTER, 'updatemmr')    
  end
end