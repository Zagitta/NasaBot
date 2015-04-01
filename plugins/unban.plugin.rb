class Unban < Plugin
  
  def start(user, args)
    @thread = Thread.new {
      while true
        sleep(300)
          @bot.send "PRIVMSG #{@bot.channel} :.unban saltymoses"    
      end
    }
    @bot.say("Nice mirc script asplosions.")
  end

  def register_functions
    register_command('start', USER::BROADCASTER, 'startunban')
  end
end