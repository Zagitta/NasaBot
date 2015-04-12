class Unban < Plugin
  
  def start(user, args)
    @thread = Thread.new {
      while true
        sleep(60)
          @bot.send "PRIVMSG #{@bot.channel} :.unban badonkadonk55"    
      end
    }
    @bot.say("Starting auto unban.")
  end

  def register_functions
    register_command('start', USER::BROADCASTER, 'startunban')
  end
end