require 'net/http'

class Commands < Plugin
  
  def initialize(bot)
    super(bot)
    @database = open_database('commands')
	@database.execute("PRAGMA foreign_keys = ON;")
    @database.execute("CREATE TABLE IF NOT EXISTS 'commands' (cmd TEXT PRIMARY KEY, response TEXT);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'modes' (name TEXT PRIMARY KEY, mode INTEGER NOT NULL);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'commanders' (user TEXT PRIMARY KEY, mode TEXT NOT NULL, reason TEXT, FOREIGN KEY(mode) REFERENCES modes(name));")
	
	@defaultModes = [["retard", 0],["dude", 1], ["cool", 2], ["nazi", 3],["hitler", 4]]
		
	@defaultModes.each do |item|
		begin
			@database.execute("INSERT INTO 'modes' VALUES (?, ?);", item)
		rescue
			#ignore
		end
	end
	
    @enabled = true	
	
    @pastebin_url = "http://pastebin.com/api/api_post.php"
    @pastebin_paste_option = "paste"
	
    @lastDate = 0
    @lastLink = ""
	@reuploadTime = 60 * 60 #60sec * 60min, time before it allows a reupload
  end
  
  # modes:
  # 0 = banned
  # 1 = invoke commands
  # 2 = 1 + add commands 
  # 3 = 2 + delete 
  def get_privs(user)
	@database.execute("SELECT modes.mode, commanders.mode AS name, commanders.reason FROM commanders INNER JOIN modes ON commanders.mode = modes.name WHERE user=? LIMIT 1;", user) do |row|
		reason = row["reason"]
		
		if((not reason.nil?) && reason.empty?)
			reason = nil
		end
		
		return Integer(row["mode"]), reason, row["name"]
	end
	
	mode = @bot.user_broadcaster?(user) ? 4 : @bot.user_mod?(user) ? 3 : 1
	
	return mode, nil, @defaultModes[mode][0]
  end
  
  def add_mode(user, args)
  
    name, mode, rest = args.split(" ")
	
	if name.nil? || (mode.nil?)
      return @bot.say("Usage: !addmode [MODE_NAME] [LEVEL]")
    end
	
	begin
		@database.execute("INSERT INTO 'modes' VALUES (?,?);", name, mode)
	rescue SQLite3::ConstraintException
		return @bot.say("Mode already exists")
	end
	
	@bot.say("Mode added")
  end
  
  def my_mode(user, args)
	privs, reason, name = get_privs(user)
		
	@bot.say("#{user} you're a " + name)
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
    	
	reason = args.count > 2 ? args[2..-1].join(' ') : nil
    
    begin 
      @database.execute("INSERT OR REPLACE INTO 'commanders' VALUES (?, ?, ?);", user, mode, reason)
      @bot.say("#{user} is now a #{mode}.")
    rescue SQLite3::ConstraintException
      @bot.say("Invalid mode.")
    end
  end  
  
  def help_mode
    @bot.say("Usage: !setmode [USER] [MODE] [REASON].")
  end
  
  def add_command(user, args)
	
	privs, reason, name = get_privs(user)
	
	if(privs < 2)
	 	return @bot.say("#{user} you're a #{name} and " + reason.nil? ? "only mods and whitelisted people are allowed to add commands" : "banned because: #{reason}")
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
    return @bot.say("#{user}, dont fucking add spam commands SwiftRage") if output.length >= @bot.message_length
    
	
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
  
	privs, reason, name = get_privs(user)
	
	if(privs < 3)
	 	return @bot.say("#{user} you're a #{name} and " + reason.nil? ? "only mods and whitelisted people are allowed to delete commands" : "banned because: #{reason}")
	end
	
    
    command = args.strip.downcase
    command = command[1..-1] if command[0] == '!'
    
    @database.execute("DELETE FROM 'commands' WHERE cmd=?;", command)
    count = @database.changes
    @bot.say("Deleted !#{command}.", true) if count > 0
  end
  
  def find_command(line)
    return unless @enabled
	
    case line
		when /:(.+?)!.+PRIVMSG\s#.+\s:\s*!(\S+)/i
		command = $2.downcase
		user = $1
		privs, reason, name = get_privs(user)
		
		if(privs < 1)
			return @bot.say("#{user} you're a #{name} and bannned from using commands" + reason.nil? ? "" : " because: #{reason}")
		end
		
		@database.execute("SELECT response FROM commands WHERE cmd=? LIMIT 1;", command) do |result|
			@bot.say(process_line(result[0], user), @bot.user_mod?(user))
		end
	end
  end
  
  def process_line(line, user)
    line = line.gsub(/\[\[user\]\]/, user)
	line = line.gsub(/\[\[rnd\]\]/, rand(1000..100000).to_s)
  
    if(line =~ /\[\[rnduser\]\]/)
	  rnduser = @bot.users.to_a.sample
	  rnduser = user if rnduser.nil?
	  line = line.gsub(/\[\[rnduser\]\]/, rnduser)
	end
	
	if(line =~ /\[\[rndmod\]\]/)
	  rndmod = @bot.moderators.to_a.sample
      rndmod = user if rndmod.nil?
	  line = line.gsub(/\[\[rndmod\]\]/, rndmod)
	end
	
	return line
  end
  
  def disable(user, args)
  
	privs, reason, name = get_privs(user)
	
	if(privs < 3)
	 	return @bot.say("#{user} you're a #{name} and " + reason.nil? ? "only mods and whitelisted people are allowed to disable commands" : "banned because: #{reason}")
	end
	     
    @enabled = false
    @bot.say("NAZI MODS!!!!!!!!!!!!", true)
  end
  
  def enable(user, args)  
  
	privs, reason, name = get_privs(user)
	
	if(privs < 3)
	 	return @bot.say("#{user} you're a #{name} and " + reason.nil? ? "only mods and whitelisted people are allowed to enable commands" : "banned because: #{reason}")
	end
	privs, reason = get_privs(user)
	     
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
  
	privs, reason, name = get_privs(user)
	
	if(privs < 1)
	 	return @bot.say("#{user} you're a #{name} and bannned from using commands" + reason.nil? ? "" : " because: #{reason}")
	end
  
  
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
  
  def gj_list(user, args)
  
	privs, reason, name = get_privs(user)
	
	if(privs < 1)
	 	return @bot.say("#{user} you're a #{name} and bannned from using commands" + reason.nil? ? "" : " because: #{reason}")
	end
	

	@database.execute("SELECT response FROM commands WHERE cmd LIKE 'gj%';") do |result|
		@bot.say(process_line(result[0], user), @bot.user_mod?(user))
	end
  end
  
  
  def register_functions
    register_command('add_command', USER::ALL, 'add')
    register_command('delete_command', USER::ALL, 'delete')
    register_command('enable', USER::ALL, 'allowpasta')
    register_command('disable', USER::ALL, 'banpasta')
    register_command('set_mode', USER::BROADCASTER, 'setmode')
    register_command('add_mode', USER::BROADCASTER, 'addmode')
    register_command('my_mode', USER::ALL, 'mymode')
    register_command('get_list', USER::ALL, 'commands') #Pozzuh addition 
    register_command('gj_list', USER::ALL, 'gjall')
    register_watcher('find_command')
  end
end