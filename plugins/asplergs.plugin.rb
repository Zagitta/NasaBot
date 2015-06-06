class Asplergs < Plugin
  
  def initialize(bot)
    super(bot)
	@rng = Random.new
  end
  
  def check_asperg(line)
  
	case line
		when /:(.+?)!.+PRIVMSG\s#.+\s:\s*!(\S+)/i
		command = $2.downcase
		user = $1
		
		if(user == "asplosions" && (@rng.rand(1.0) < 0.05))
			return @bot.say("stfu asplosions nobody likes you"))
		end
		end
	end
  end
  

  def register_functions
    register_watcher('check_asperg')
  end
end