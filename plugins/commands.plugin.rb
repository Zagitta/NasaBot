require 'net/http'

class Commands < Plugin
  
  def initialize(bot)
    super(bot)
    @database = open_database('commands')
    @database.execute("CREATE TABLE IF NOT EXISTS 'commands' (cmd TEXT PRIMARY KEY, response TEXT);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'commanders' (user TEXT PRIMARY KEY, mode INTEGER, reason TEXT);")
    @enabled = true	
	
    @pastebin_url = "http://pastebin.com/api/api_post.php"
    @pastebin_paste_option = "paste"
	
    @lastDate = 0
    @lastLink = ""
	
    @reuploadTime = 60 * 60 #60sec * 60min, time before it allows a reupload
	@overrideSpam = false
  end
  
  # modes:
  # 0 = banned
  # 1 = invoke commands
  # 2 = 1 + add commands 
  # 3 = 2 + delete 
  def get_privs(user)
	@database.execute("SELECT mode, reason FROM commanders WHERE user=? LIMIT 1", user) do |row|
	  return Integer(row["mode"]), row["reason"]
	end
	return nil
  end
  
  def set_mode(user, args)
    if args.strip.empty?
      return help_mode
    end
    
    args = args.split(" ")
	
	if args.count < 2
      return help_mode
    end
    	
    user = args[0].gsub(/\s*/, '').downcase
	mode = args[1].gsub(/\s*/, '').downcase
    
	reason = args.count > 2 ? args[2..-1].join(' ') : ""
    
    begin 
      @database.execute("INSERT OR REPLACE INTO 'commanders' VALUES (?, ?, ?);", user, mode, reason)
      @bot.say("Set mode of #{user} to #{mode}.")
    rescue SQLite3::ConstraintException
      @bot.say("Error setting mode.", true)
    end
  end  
  
  def help_mode
    @bot.say("Usage: !setmode [USER] [MODE] [REASON].")
  end
  
  def override_spam
    @overrideSpam = true
  end
  
  def override_spam_disable
    @overrideSpam = false
  end
  
  def add_command(user, args)
	
	privs, reason = get_privs(user)
	
    if (privs == nil && @bot.user_mod?(user) == false)
      return @bot.say("#{user}, only mods and whitelisted people are allowed to add commands")
    end
    
	if(privs != nil && privs < 2)
		return @bot.say("#{user}, you're banned from adding commands: #{reason}")
	end
	
	if args.strip.empty?
      return help
    end
    
    command = args.split(" ")[0].gsub(/\s*/, '').downcase
    if command[0] == '!'
      command = command[1..-1]
    end
    
    output = args.split(" ")[1..-1].join(' ')
    
    return help if command.empty? || output.empty?
    return @bot.say("pls no spam, #{user}.") if command.length > 15
    return @bot.say("#{user}, dont fucking add spam commands SwiftRage") if output.length >= CONFIG::MESSAGEMAXLENGTH or @overrideSpam
    
	
	case output
		when /http:\/\/puu.sh\/[\S&&[^.]]+.(jpg|png|jpeg)/i
			return @bot.say("Go fucking host that shit on imgur, puu.sh links expire!")
	end
	
    begin
      @database.execute("INSERT INTO 'commands' VALUES (?, ?);", command, output)
      @bot.say("Added !#{command}.", true)
    rescue SQLite3::ConstraintException
      @bot.say("!#{command} was not added.", true)
    end 
  end
  
  def help
    @bot.say "Usage: !add [COMMAND] [OUTPUT]. Example: !add bot nasabot best bot"
  end
  
  def delete_command(user, args)
  
	privs, reason = get_privs(user)
	
    if (privs == nil && @bot.user_mod?(user) == false)
      return @bot.say("#{user}, only mods and whitelisted people are allowed to delete commands")
    end
    
	if(privs != nil && privs < 3)
		return @bot.say("#{user}, you're banned from deleting commands: #{reason}")
	end
    
    command = args.strip
    command = command[1..-1] if command[0] == '!'
    
    @database.execute("DELETE FROM 'commands' WHERE cmd=?;", command)
    count = @database.changes
    @bot.say("Deleted !#{command}.", true) if count > 0
  end
  
  def find_command(line)
    return unless @enabled
	
    case line
		when /:(.+?)!.+PRIVMSG\s#.+\s:\s*!(\S+)/i
		command = $2
		user = $1
		privs, reason = get_privs(user)
				
		if(privs != nil && privs < 1)
			return @bot.say("#{user}, you're banned from using commands: #{reason}")
		end
		
		@database.execute("SELECT response FROM commands WHERE cmd=? LIMIT 1;", command) do |result|
			@bot.say(result[0].gsub(/\[\[user\]\]/, user), @bot.user_mod?(user))
		end
	end
  end
  
  def disable(user, args)
  
	privs, reason = get_privs(user)
	
    if (privs == nil && @bot.user_mod?(user) == false)
      return @bot.say("#{user}, only mods and whitelisted people are allowed to delete commands")
    end
    
	if(privs != nil && privs < 3)
		return @bot.say("#{user}, you're banned from disabling commands: #{reason}")
	end
     
    @enabled = false
    @bot.say("NAZI MODS!!!!!!!!!!!!", true)
  end
  
  def enable(user, args)  
  
	privs, reason = get_privs(user)
	
    if (privs == nil && @bot.user_mod?(user) == false)
      return @bot.say("#{user}, only mods and whitelisted people are allowed to delete commands")
    end
    
	if(privs != nil && privs < 3)
		return @bot.say("#{user}, you're banned from enabling commands: #{reason}")
	end
     
    @enabled = true
    @bot.say("FREEDOM!!!!!!!!!!!!", true)
  end
  
  
  def get_commands_string
	string = ""
  
	begin	
      data = @database.execute("SELECT * FROM commands")
		
	  data.each do |row|
	    string += "!"
		string += row['cmd']
		string += " - "
		string += row['response']
		string += "\n"
	  end
	rescue => e #error
	  #puts "Error occured: #{e}!"
	  string = ""
	end  
	 
	 return string
  end
  
  def pastebin_upload(data)
	requestData = { "api_option" => @pastebin_paste_option, "api_dev_key" => CONFIG::PASTBIN_KEY, "api_paste_code" => data }
  
	uri = URI.parse(@pastebin_url)
	response = Net::HTTP.post_form(uri, requestData)
	
	@lastDate = Time.now.to_i #Report time even if failure
	return response.body
  end
  
  def get_list(user, args) #command entry 
    if not @lastLink.empty?	
	  currTime = Time.now.to_i  
	  difference = currTime - @lastDate
	  cooldownTime = @reuploadTime

	  if difference <= cooldownTime
	    @bot.say("Command list: #{@lastLink}")
		return
	  end
	end
  
    data = get_commands_string
	
	if data.empty? #failure 
	  if not @lastLink.empty?
	    @bot.say("Command list: #{@lastLink}")
	  else 
	    @bot.say("Failed to get command list.")
	  end
	  
	  return
	end
	
    response = pastebin_upload(data)
	
	if response.start_with?("Bad") || response.start_with?("Post") #failure	  
	  if not @lastLink.empty?
	    @bot.say("Command list: #{@lastLink}")
	  else 
	    @bot.say("Failed to get command list.")
	  end
	  
	  return
	else
	  @lastLink = response
	  @bot.say("Command list: #{@lastLink}")
	end
  end
  
  
  def register_functions
    register_command('add_command', USER::ALL, 'add')
    register_command('delete_command', USER::ALL, 'delete')
    register_command('enable', USER::ALL, 'allowpasta')
    register_command('disable', USER::ALL, 'banpasta')
    register_command('set_mode', USER::BROADCASTER, 'setmode')
    register_command('get_list', USER::ALL, 'commands') #Pozzuh addition 
    register_command('override_spam', USER::BROADCASTER) 
    register_command('override_spam_disable', USER::BROADCASTER)
    register_watcher('find_command')
  end
end