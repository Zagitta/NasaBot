class Linkban < Plugin
  def initialize(bot)
    super(bot)
    @database = open_database("linkban")
    @database.execute("CREATE TABLE IF NOT EXISTS 'blacklist' (url TEXT PRIMARY KEY, timeout INTEGER);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'rules' (input TEXT PRIMARY KEY, output TEXT);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'mod_whitelist' (username TEXT PRIMARY KEY);")
    
    @blacklist = nil
    load_list
  end
  
  def add_help
    @bot.say("USAGE: !urlban [URL] [SECONDS]. Example: !urlban example.com 600. Use 0 seconds for permaban.")
  end
  
  def add_url(user, args)
    return unless is_whitelist?(user)
    
    args = args.split(" ")
    return add_help if args.length != 2
    
    url = args[0].gsub(/\s/, "")
    timeout = args[1].to_i
    
    return @bot.say("'#{url}' is not a valid url.") if url !~ /(?:https?:\/\/)?(?:www\.)?(?:[a-zA-Z0-9-]+\.)?([a-zA-Z0-9-]+\.[a-zA-Z]+)\/?/
    url = $1
    
    begin
      @database.execute("INSERT INTO blacklist VALUES(?, ?);", url, timeout)
      @bot.say("Added '#{url}' to banlist. (#{timeout})", true)
      load_list
    rescue SQLite3::ConstraintException
      @bot.say("'#{url}' was not added.", true)
    end
  end
  
  def load_list
    @blacklist = Array.new
    urls = @database.execute("SELECT url, timeout FROM blacklist;")
    return if urls.nil?
    
    urls.each do |url|
      @blacklist << {regex: create_regex(url["url"]), timeout: url["timeout"] }
    end
  end
  
  def create_regex(url)
    rules = @database.execute("SELECT input, output FROM rules;")
    return url if rules.nil?
    
    regex = url
    rules.each do |rule|
      regex = regex.gsub(rule["input"], rule["output"])
    end   
    return regex
  end
  
  def add_rule(user, args)
    args = args.strip.split(">>")
    target = args[0].strip
    replacement = args[1].nil? ? "" : args[1].strip
    begin
      @database.execute("INSERT INTO rules VALUES(?, ?);", target, replacement)
      @bot.say("Added rule '#{args[0]}'->'#{args[1]}'", true)
      load_list
    rescue SQLite3::ConstraintException
      @bot.say("Rule '#{args[0]}'->'#{args[1]}' was not added.", true)
    end    
  end
  
  def delete_url(user, args)
    return unless is_whitelist?(user)
    url = args.strip.gsub(/\s/, "")
    begin
      @database.execute("DELETE FROM blacklist WHERE url=?;", url)
      if @database.changes > 0
        @bot.say("Removed '#{url}' from banlist.")
        load_list
      end
    end  
  end
  
  def delete_rule(user, args)
    target = args.strip
    begin
      @database.execute("DELETE FROM rules WHERE input=?;", target)
      if @database.changes > 0
        @bot.say("Deleted rule for #{target}.")
        load_list
      end     
    end
  end
  
  def parse_lines(line)
    return unless @bot.user_mod?(CONFIG::USER)
    
    case line
    when /:(.+?)!.+PRIVMSG\s#.+\s:(.*)/i
      user = $1
      return if @bot.user_mod?(user)
      
      message = $2.gsub(/\s/, "")
      @blacklist.each do |regex|
        if message =~ /#{regex[:regex]}/i
          if regex[:timeout] == 0
            @bot.send "PRIVMSG #{@bot.channel} :.ban #{user}"
          else
            @bot.send "PRIVMSG #{@bot.channel} :.timeout #{user} #{regex[:timeout]}"
          end          
          return
        end
      end
    end   
  end
  
  def debug(user, args)
    @bot.say(@blacklist.inspect)
  end
  
  def add_user(user, args)
    target = args.strip
    begin
      @database.execute("INSERT INTO mod_whitelist VALUES(?);", target)
      @bot.say("Added #{target} to mod whitelist.", true)
    rescue SQLite3::ConstraintException
      @bot.say("#{target} already is on mod whitelist.")
    end
  end
  
  def remove_user(user, args)
    target = args.strip
    begin
      @database.execute("DELETE FROM mod_whitelist WHERE username=?;", target)
      @bot.say("Removed #{target} from mod whitelist.") if @database.changes > 0
    end
  end
  
  def is_whitelist?(user)
    whitelist = @database.get_first_row("SELECT COUNT(*) AS count FROM mod_whitelist WHERE username=?;", user)
    return true if whitelist["count"] == 1
    return false
  end
  
  def register_functions
    register_command('add_rule', USER::BROADCASTER, 'urlrule')
    register_command('add_url', USER::MODERATOR, 'urlban')
    register_command('delete_rule', USER::BROADCASTER, 'urlrulerm')
    register_command('delete_url', USER::MODERATOR, 'urlbanrm')
    register_command('debug', USER::BROADCASTER, 'urldebug')
    register_command('add_user', USER::BROADCASTER, 'urlallow')
    register_command('remove_user', USER::BROADCASTER, 'urlremove')
    register_watcher('parse_lines')
  end
end