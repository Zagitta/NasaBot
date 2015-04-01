class Giveaway < Plugin
  def initialize(bot)
    super(bot)
    @database = open_database('giveaway')
    @database.execute("CREATE TABLE IF NOT EXISTS 'giveaways' (id INTEGER PRIMARY KEY AUTOINCREMENT, time INTEGER);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'entries' (giveaway_id INTEGER, username TEXT, PRIMARY KEY(giveaway_id, username));")
    @current_id = nil
    @last_announce = 0
  end
  
  def start_giveaway(user, args)
    return @bot.say("There is already a giveaway running.", true) unless @current_id.nil?
    time = Time.now.to_i
    @database.execute("INSERT INTO giveaways(time) VALUES(?);", time)
    rowid = @database.execute("SELECT id FROM giveaways ORDER BY time DESC LIMIT 1;").first["id"]
    if  rowid > 0
      @current_id = rowid
      @bot.say("Giveaway started. Type !giveaway in chat to participate. Good luck!", true)
    end
  end
  
  def enter(user, args)
    return @bot.say("There is no giveaway running.", @bot.user_mod?(user)) if @current_id.nil?
    user = user
    time = Time.now.to_i
    begin
      @database.execute("INSERT into entries VALUES(?, ?);", @current_id, user)
      if time - @last_announce > 30
        @bot.say("Added user(s) to the giveaway.", true)
        @last_announce = time
      end
    rescue SQLite3::ConstraintException
      return
    end
  end
  
  def end_giveaway(user, args)
    return if @current_id.nil?
    @current_id = nil
    @bot.say("Giveaway is over. Draw a winner with !winrar.")
  end
  
  def draw_winner(user, args)
    id = @database.execute("SELECT id FROM giveaways ORDER BY time DESC LIMIT 1;").first["id"]
    winner = @database.execute("SELECT username FROM entries WHERE giveaway_id=? ORDER BY RANDOM() LIMIT 1;", id).first["username"]
    @bot.say("The winner is... #{winner}!", true)
  end
  
  def register_functions
    register_command('start_giveaway', USER::BROADCASTER, 'startgiveaway')
    register_command('end_giveaway', USER::BROADCASTER, 'endgiveaway')
    register_command('enter', USER::ALL, 'giveaway')
    register_command('draw_winner', USER::BROADCASTER, 'winrar')
  end
end