class Multikappa < Plugin 
  
  def initialize(bot)
    super(bot)
    @database = open_database('kappas')
    @database.execute("CREATE TABLE IF NOT EXISTS 'multikappas' (user TEXT, kappas INTEGER);")
  end
  
  def user_highscore(user, args)
    result = @database.execute("SELECT COUNT(*) AS count, MAX(kappas) as highscore, SUM(kappas) AS sum FROM 'multikappas' WHERE user=?;", user)[0]
    return if result["count"] == 0
    highscore = result["highscore"]
    average = (result["sum"].to_f/result["count"].to_f).round(2)
    @bot.say("#{user} highscore: #{highscore} x multikappa. Your average: #{average} in #{result["count"]} multikappas.")
  end
  
  def highscore(user, args)
    result = @database.execute("SELECT user,kappas FROM multikappas ORDER BY kappas DESC LIMIT 1;")[0]
    @bot.say("Highscore is #{result[1]} Kappas by #{result[0]} Kreygasm")
  end
  
  def is_highscore?(kappacount)
    result = @database.execute("SELECT COUNT(*) as count, MAX(kappas) as highscore FROM multikappas;")[0]
    return false if result["count"] == 0
    highscore = result["highscore"]
    if kappacount > highscore
      return true
    else
      return false
    end
  end
  
  def multikappa(user, args)
    return unless args.strip.empty?
    kappacount = multi_kappa_count
    kappa = "Kappa " * kappacount
    
    highscore = is_highscore?(kappacount) ? "THAT'S A NEW HIGHSCORE Kreygasm" : ""
    
    if kappacount == 1
      @bot.say "#{user} you only kappa once #{kappa}"
    else
      @bot.say "#{user} got #{kappacount} kappas! #{kappa}#{highscore}"
    end
    @database.execute("INSERT INTO 'multikappas' VALUES (?, ?);", user, kappacount)
  end
  
  def is_kappa?
    pls = 1 + rand(100)
    if pls <= 69
      return true
    else
      return false
    end
  end
  
  def multi_kappa_count
    kappas = 1
    while is_kappa?
      kappas = kappas+1
    end
    return kappas
  end

  def register_functions
    register_command('multikappa')
    register_command('user_highscore', USER::ALL, 'myscore')
    register_command('highscore')
  end 
end