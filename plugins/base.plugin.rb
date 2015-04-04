class Base < Plugin
  
  def mod(user, args)
    @bot.say("#{user} has a sword.")
  end
  
  def broadcaster(user, args)
    @bot.say("#{user} WOW UR A STREAMER Kreygasm")  
  end
  
  def quit(user, args)
    @bot.quit
  end
  
  def usercount(user, args)
    viewercount = @bot.users.size
    @bot.say("There are #{viewercount} users in chat.")
  end
  
  def set_message_length(user, args)
    if args.strip.empty?
      return @bot.say("Max message length: #{@bot.message_length}")
    end
  
    length = args.strip.to_i
    @bot.message_length = length
    @bot.say("Set message length to #{length} characters.")
  end
  
  def history_length(user, args)
    data = @bot.message_queue.size
    @bot.say("Duplicate messages ignored for last #{data[:history_length]} messages. (#{data[:history_length] == data[:history_size]})", true)
  end
  
  def register_functions
    register_command('mod', USER::MODERATOR)
    register_command('broadcaster', USER::BROADCASTER, 'streamer')
    register_command('quit', USER::BROADCASTER)
    register_command('usercount', USER::BROADCASTER)
    register_command('set_message_length', USER::BROADCASTER, 'maxlen')
    register_command('history_length', USER::BROADCASTER, 'dup')
  end
end