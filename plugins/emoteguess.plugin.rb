require 'net/http'
require 'json'

class EmoteGuess < Plugin
  def initialize(bot)
    super(bot)
	
	@enabled = true
	@say_raw = false
	
	@emoteArray = Array.new
	jsonEmotes = Net::HTTP.get(URI.parse('http://twitchemotes.com/global.json'))
	jsonData = JSON.parse(jsonEmotes)
	
    jsonData.each do |emote|
      @emoteArray << emote[0]
    end

  end
  
  def find_hint(line)
    return unless @enabled
	
	case line
      when /:(.+?)!.+PRIVMSG\s#.+\s:\s*hint\s#.:\s(.+)/i #"Hint #x: K _ _ _ _
	  hint = $2
	  user = $1
	  
	  hint = hint.delete(' ') #strip whitespace
	  hint = hint.strip
      hint = hint.gsub('_', '.') #_ --> .
	  hint = "^" + hint
	  hint = hint + "$"
	  reg = Regexp.new(hint)
	  
	  emotes = @emoteArray
	  
	  resultArray = emotes.select {|word| word.match(reg)} #select all matching

	  if @say_raw
	    @bot.say_raw(resultArray.sample) unless resultArray.empty? #pick one random matching
	  else
	    @bot.say(resultArray.sample) unless resultArray.empty? #pick one random matching
	  end
	end
	
  end
  
  def enable_guess(user, args)
	@bot.say("Enabled guessing.")
	@enabled = true
  end
  
  def disable_guess(user, args)
	@bot.say("Disabled guessing.")
	@enabled = false
  end
  
  def register_functions
    register_command('enable_guess', USER::MODERATOR)
    register_command('disable_guess', USER::MODERATOR)
	register_watcher('find_hint')
  end
end