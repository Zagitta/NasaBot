class Mitsuketa < Plugin
  def mitsuketa(user, args)
    chance = 1 + rand(100)
    if chance > 98
      return @bot.say("ლ(ಠ益ಠლ) KICK PRESVU INVITE KHAREESE ლ(ಠ益ಠლ)", true)
    elsif chance > 75
      return @bot.say("༼ つ ◕_◕ ༽つ KICK PRESVU INVITE KHARESEE ༼ つ ◕_◕ ༽つ", true)
    else
      return @bot.say("IS SING PLAYING WITH KHAREESE", true)
    end
  end
  
  def register_functions
    register_command('mitsuketa')
  end
end