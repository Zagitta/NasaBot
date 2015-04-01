class Bellepics < Plugin
  
  def initialize(bot)
    super(bot)
    @database = open_database('whitelist')
    @database.execute("CREATE TABLE IF NOT EXISTS 'whitelist' (username TEXT PRIMARY KEY);")   
  end
  
  def is_whitelist?(user)
    whitelist = @database.get_first_row("SELECT COUNT(*) AS count FROM whitelist WHERE username=?;", user)
    return true if whitelist["count"] == 1
    return false
  end
  
  def bellepics(user, args)
    if is_whitelist?(user)
      @bot.say("#{user}, check your PMs! ;p")
    else
      @bot.say("You are permanently banned from using this command. (go fuck yourself #{user})")
    end
  end
  
  def allow(user, args)
    target = args.strip
    return if is_whitelist?(target)
    
    begin
      @database.execute("INSERT INTO whitelist VALUES(?);", target)
      @bot.say("Added #{target} to whitelist.")
    rescue SQLite3::ConstraintException
      @bot.say("#{target} was not added.")
    end
    
    
  end
  
  def remove(user, args)
    target = args.strip
    return if !is_whitelist?(target)
    
    begin
      @database.execute("DELETE FROM whitelist WHERE username=?;", target)
      @bot.say("Permanently banned #{target}.")
    rescue SQLite3::ConstraintException
      @bot.say("#{target} could not be removed.")
    end
  end
  
  def register_functions
    register_command('bellepics')
    register_command('allow', USER::BROADCASTER, 'whitelist')
    register_command('remove', USER::BROADCASTER, 'permaban')
  end
end