require 'time'

class Hiccup < Plugin
  def initialize(bot)
    super(bot)
    @database = open_database("hiccups")
    @database.execute("CREATE TABLE IF NOT EXISTS 'hiccups' (time TEXT);")
  end
  
  def add_hiccup(user, args)
    time = Time.new
    @database.execute("INSERT INTO hiccups VALUES(?);", time.to_s)
    @bot.say("Added hiccup.")
  end
  
  def hiccups(user, args)
    data = @database.execute("SELECT COUNT(*) AS hiccups FROM hiccups;")[0]
    @bot.say("Total hiccups: #{data["hiccups"]}.")
  end
  
  def populate(user, args)
    amount = args.strip.to_i
    time = Time.new
    amount.times do
      @database.execute("INSERT INTO hiccups VALUES(?);", time.to_s)
    end
    @bot.say("Added #{amount} hiccups.")
    
  end
  
  def register_functions
    register_command('add_hiccup', USER::MODERATOR, 'hic')
    register_command('hiccups', USER::ALL, 'hiccups')
    register_command('populate', USER::BROADCASTER, 'hicset')
  end
end