class Badonk < Plugin
  
  def start(user, args)
    @thread = Thread.new {
      while true
        sleep(600)
          @bot.say("Reminder to sign petittion to free chat user badonkadonk55: https://www.change.org/p/twitch-tv-unban-my-good-friend-badonkadonk55?just_created=true")    
      end
    }
    @bot.say("Starting auto unban.")
  end

  def register_functions
    register_command('start', USER::BROADCASTER, 'startunban')
  end
end