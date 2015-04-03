require 'nokogiri'
require 'open-uri'

class Imgur < Plugin
   
  def initialize(bot)
    super(bot)
		
	@thread = Thread.new {
      while true
		
		puts "opening: " + CONFIG::TEAM_LINK
		
		doc = Nokogiri::HTML(open(CONFIG::TEAM_LINK))
				
		@matches = doc.css('#gb-matches > tbody > tr').map { |link|
			opp1, opp2 = link.css('.opp')
			live = link.css('.live-in');
			
			text = opp1.text.strip + " vs " + opp2.text.strip + " in " + live.text.strip
			
			puts text
			
			text
		}
		
        sleep(300)		
      end
    }
	
  end
  
  def next_match(user, args)
	msg = @matches != nil ? @matches.join(', ') : "No matches"
	@bot.say(msg)
  end
  
  def register_functions
	register_command('next_match', USER::ALL, 'matches')
  end
end