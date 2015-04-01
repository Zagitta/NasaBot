class Kappbot < Plugin
  
  def start(user, args)
    @thread = Thread.new {
      while true
        sleep(300)
          @bot.send "PRIVMSG #{@bot.channel} :.ban Kappbot"    
      end
    }    
  end

  def register_functions
    register_command('start', USER::BROADCASTER, 'LAUNCHNUKES')
  end
end