class Unban < Plugin
  
  def initialize(bot)
    super(bot)
	@unban_all = false
    @database = open_database('unban')
    @database.execute("CREATE TABLE IF NOT EXISTS 'users' (user TEXT PRIMARY KEY);")
  end
  
  def check_ban(line)
    case line
      when /:.+CLEARCHAT.+:(.+)/i
      user = $1.strip().downcase()
	  
	  if @unban_all
		@bot.send "PRIVMSG #{@bot.channel} :.unban #{user}"
	  else	  
		@database.execute("SELECT user FROM 'users' WHERE user LIKE ?;", user) do |row|
			@bot.send "PRIVMSG #{@bot.channel} :.unban #{user}"
			return
		end
	  end
	end
  end
  
  def anti_nazi(user, args)
	
    args = args.strip
  
    if args.empty? or args.split.length != 1
	  return @bot.say("Usage: !anti_nazi <flag>")
	end
	
	args = args.split
	
	flag = (args[0] == "true" or args[0] == "1") ? true : false
	
	@unban_all = flag
	
	flag = flag ? "Enabled" : "Disabled"
	
	@bot.say (flag + " anti nazi mode")
  end
  
  def auto_unban(user, args)
    args = args.strip
  
    if args.empty? or args.split.length < 2 or args.split.length > 2
	  return @bot.say("Usage: !auto_unban <user> <flag>")
	end
	
	args = args.split
	
	user = args[0]
	flag = (args[1] == "true" or args[1] == "1") ? true : false
	
	if flag then
	  @database.execute("INSERT INTO 'users' VALUES (?);", user.strip().downcase())
	  @bot.say "Added #{user} to auto-unban."
	else
	  @database.execute("DELETE FROM 'users' WHERE user = ?;", user.strip().downcase())
	  @bot.say "Removed #{user} from auto-unban."
	end
  end

  def register_functions
    register_watcher('check_ban')
	register_command('auto_unban', USER::BROADCASTER)
	register_command('anti_nazi', USER::BROADCASTER)
  end
end