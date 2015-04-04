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
  
  def disable_cmd(user, args)
    if args.strip.empty?
	  return @bot.say("Usage: !disable_cmd <command>")
	end
	
	command = args.strip
	@bot.say @bot.enable_command(command, false) ? "Successfully disabled #{command}." : "Couldn't disable #{command}."
  end
  
  def enable_cmd(user, args)
    if args.strip.empty?
	  return @bot.say("Usage: !enable_cmd <command>")
	end
	
	command = args.strip
	@bot.say @bot.enable_command(command, true) ? "Successfully enabled #{command}." : "Couldn't enable #{command}."
  end
  
  def load_plugin(user, args)
    if args.strip.empty?
	  return @bot.say("Usage: !load_plugin <plugin>")
	end
	
	plugin = args.strip
	@bot.say @bot.load_plugin_file(plugin) ? "Successfully loaded #{plugin}." : "Couldn't load #{plugin}."
  end
  
  def unload_plugin(user, args)
    if args.strip.empty?
	  return @bot.say("Usage: !unload_plugin <plugin>")
	end
	
	plugin = args.strip
	@bot.say @bot.unload_plugin(plugin) ? "Successfully unloaded #{plugin}." : "Couldn't unload #{plugin}."
  end
  
  def reload_plugin(user, args)
    if args.strip.empty?
	  return @bot.say("Usage: !reload_plugin <plugin>")
	end
	
	plugin = args.strip
	
	@bot.say (@bot.unload_plugin(plugin) and @bot.load_plugin_file(plugin)) ? "Successfully reloaded #{plugin}" : "Couldn't reload #{plugin}" 
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
	
	register_command('disable_cmd', USER::BROADCASTER)
	register_command('enable_cmd', USER::BROADCASTER)
	register_command('load_plugin', USER::BROADCASTER)
	register_command('unload_plugin', USER::BROADCASTER)
	register_command('reload_plugin', USER::BROADCASTER)
  end
end