require 'nokogiri'
require 'open-uri'

class Matchticker < Plugin
  def initialize(bot)
    super(bot)
	
	@matches = nil
	@lastDate = 0
	@reuploadTime = 60 * 5 #60sec * 5min
  end
  
  def next_match(user, args)
	currTime = Time.now.to_i  
	difference = currTime - @lastDate
	cooldownTime = @reuploadTime

	if difference >= cooldownTime
		doc = Nokogiri::HTML(open(CONFIG::TEAM_LINK))
		
		@matches = doc.css('#gb-matches > tbody > tr').map { |link|
			opp1, opp2 = link.css('.opp')
			live = link.css('.live-in');
			
			text = opp1.text.strip + " vs " + opp2.text.strip + " in " + live.text.strip
			
			text
		}
	end
    
	msg = @matches != nil ? @matches.join(', ') : "No matches found"
	@bot.say(msg)
  end
  
  def register_functions
	register_command('next_match', USER::ALL, 'matches')
  end
end