class Arrow < Plugin

  ARROW_COOLDOWN = 17
  ARROW_MANACOST = 100
  
  HP = 322
  MANA = 250
  DEATHTIME = 600
  BASE_DAMAGE = 90
  DAMAGE_MULT = 20
  
  PASSIVE_REGEN = 0.5
  PASSIVE_HP = 0.03
  
  def initialize(bot)
    super(bot)
    @database = open_database('potm')
    @database.execute("CREATE TABLE IF NOT EXISTS 'players' (user TEXT PRIMARY KEY, hp INTEGER, mana INTEGER, last_arrow INTEGER, last_fountain INTEGER, last_refresh INTEGER);")
    @database.execute("CREATE TABLE IF NOT EXISTS 'combat_log' (killer TEXT, target TEXT);")
  end
  
  def arrow(user, args)
    #check arrow cooldown
    create_user(user)
    return unless can_arrow?(user)  
    
    
    #check miss chance       
    
    
    #select random target and create user
    target = @bot.users.to_a.sample
    create_user(target)
    
    #damage and mana handling
    message = handle_arrow(user, target, stun_duration(user, target))
    
    #chat message
    @bot.say(message)
  end
  
  def can_arrow?(user)
    refresh(user)
    data = @database.execute("SELECT last_arrow, last_fountain, mana FROM 'players' WHERE user=?;", user).first
    time = Time.now.to_i
    if time - data["last_arrow"].to_i > ARROW_COOLDOWN && time - data["last_fountain"].to_i > DEATHTIME && data["mana"].to_i >= ARROW_MANACOST
      return true
    end 
    
    return false
  end
  
  def handle_arrow(user, target, duration)
    result = ""
    damage = BASE_DAMAGE + duration * DAMAGE_MULT
    time = Time.now.to_i
    
    #handle user
    user_mana = @database.execute("SELECT mana FROM 'players' WHERE user=?;", user).first["mana"].to_i
    result_mana = user_mana - ARROW_MANACOST
    @database.execute("UPDATE 'players' SET last_arrow=?, mana=? WHERE user=?;", time, result_mana, user)
    
    return "#{user} missed the arrow and has #{result_mana} mana left." if !arrow_hits?
    
    
    if target == @bot.channel[1..-1]
      result += "#{user} HITS #{target}. GET REKT NUB SwiftRage. Stuns for #{duration} seconds and deals #{damage} damage. "
    else
      result += "#{user} hits #{target} with an arrow, stuns for #{duration} seconds and deals #{damage} damage. "
    end
    
    
    #handle target
    target_hp = @database.execute("SELECT hp FROM 'players' WHERE user=?;", target).first["hp"].to_i
    result_hp = target_hp - damage
    @database.execute("UPDATE 'players' SET hp=? WHERE user=?;", result_hp, target)
    
    
    #handle death
    if result_hp <= 0
      result += "#{target} got sniped Kreygasm "
      kill(user, target)
    else
      result += "#{target} has #{result_hp} hp left. "
    end
    
    result += "#{user} has #{result_mana} mana left."
    
    return result.to_s
    
  end
  
  def kill(user, target)
    time = Time.now.to_i
    @database.execute("UPDATE 'players' SET hp=?, mana=?, last_fountain=? WHERE user=?;", HP, MANA, time, target)
    @database.execute("INSERT INTO 'combat_log' VALUES(?, ?);", user, target)
  end
  
  def create_user(user)
    time = Time.now.to_i
    begin
      @database.execute("INSERT INTO 'players' VALUES(?, ?, ?, ?, ?, ?)", user, HP, MANA, 0, 0, time)
      return true
    rescue SQLite3::ConstraintException
      return false
    end
    
  end
  
  def arrow_hits?
    viewercount = @bot.users.size
    randomize = 15 + rand(5)
    hit_cap = 100 - Math::log10(viewercount) * randomize
    return true if 1+rand(100) > hit_cap
    return false
  end
  
  def stun_duration(user, target)
    return 0.5 * rand(1..10)
  end
  
  def refresh(user)
    data = @database.execute("SELECT hp, mana, last_refresh FROM players WHERE user=?;", user).first
    time = Time.now.to_i
    delta = time - data["last_refresh"].to_i
    regen = (delta * PASSIVE_REGEN).round
    hp_regen = (delta * PASSIVE_HP).round
    
    result_mana = data["mana"] + regen
    result_hp = data["hp"] + hp_regen
    
    result_mana = MANA if result_mana > MANA
    result_hp = HP if result_hp > HP
    
    @database.execute("UPDATE players SET hp=?, mana=?, last_refresh=? WHERE user=?;", result_hp, result_mana, time, user)
    
  end
  
  def status(user, args)
    create_user(user)
    refresh(user)
    data = @database.execute("SELECT hp, mana, last_arrow, last_fountain, (SELECT COUNT(*) FROM combat_log WHERE killer=?) AS kills,(SELECT COUNT(*) FROM combat_log WHERE target=?) AS deaths FROM players WHERE user=?;", user, user, user).first
    time = Time.now.to_i
    result = "Player: #{user}, HP: #{data["hp"]} Mana: #{data["mana"]}. "
    if time - data["last_arrow"] > ARROW_COOLDOWN
      result += "!arrow is off cooldown. "
    else
      cooldown = ARROW_COOLDOWN - (time - data["last_arrow"].to_i)
      result += "!arrow is on cooldown for #{cooldown} seconds. "
    end
    
    if time - data["last_fountain"] < DEATHTIME
      regen_time = DEATHTIME - (time - data["last_fountain"].to_i)
      result += "In base and can't use !arrow for #{regen_time} seconds. "
    end
    
    result += "K/D #{data["kills"]}/#{data["deaths"]}."
    
    @bot.say(result)
  end
  
  def noobs
    @data = @database.execute("SELECT target, COUNT(*) AS deaths FROM combat_log GROUP BY target ORDER BY deaths DESC LIMIT 5;")
  end
  
  def register_functions
    register_command('status')
    register_command('arrow')
  end
end