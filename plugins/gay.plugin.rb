class Gay < Plugin
  def gay(user, args)
    random = rand.to_s[2..6]
    @bot.say("im gay lol #{random}")
  end
  
  def register_functions
    register_command('gay', USER::ALL, 'imgaylol')
  end
end