require 'time'

class Deaths < Plugin
  def initialize(bot)
    super(bot)
    @database = open_database("deaths")
    @database.execute("CREATE TABLE IF NOT EXISTS 'deaths' (time TEXT);")
    @last_death = 0
  end
  
  def add_death(user, args)
    time = Time.new
    return unless time.to_i - @last_death > 10
    @database.execute("INSERT INTO deaths VALUES(?);", time.to_s)
    @bot.say("YOU DIED", true)
  end
  
  def deaths(user, args)
    data = @database.execute("SELECT COUNT(*) AS deaths FROM deaths;")[0]
    @bot.say("Total deaths: #{data["deaths"]}.")
  end
  
  def populate(user, args)
    amount = args.strip.to_i
    time = Time.new
    amount.times do
      @database.execute("INSERT INTO deaths VALUES(?);", time.to_s)
    end
    @bot.say("Added #{amount} deaths.")
    
  end
  
  def register_functions
    register_command('add_death', USER::MODERATOR, 'youdied')
    register_command('deaths', USER::ALL, 'deaths')
    register_command('populate', USER::BROADCASTER, 'hicset')
  end
end