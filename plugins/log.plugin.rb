#for channel sing_sing only...

require 'net/http'
require './config'

class Log < Plugin
  def initialize(bot)
    super(bot)
    @database = open_database('chatlog')
    @database.execute("CREATE TABLE IF NOT EXISTS 'chatlog' (id INTEGER PRIMARY KEY, user TEXT, time INTEGER, message TEXT);")
	
	@BASE_URL = "http://overrustlelogs.net/Sing_sing%20chatlog/[[month]]%20[[year]]/userlogs/[[user]].txt"
  end

  def do_log(user, args)	
	username = args.strip.empty? ? user : args.strip
	username = username.downcase
	
	time = Time.now
	month = time.strftime("%B") #shouldn't be localized
	year = time.year.to_s
	
	url = @BASE_URL.gsub(/\[\[month\]\]/, month).gsub(/\[\[year\]\]/, year).gsub(/\[\[user\]\]/, username)
	
	@bot.say("User log: #{url}")
  end
   
  def do_random(user, args)   
	username = args.strip.empty? ? user : args.strip
	username = username.downcase
	
	time = Time.now
	month = time.strftime("%B") #shouldn't be localized
	year = time.year.to_s
	
	url = @BASE_URL.gsub(/\[\[month\]\]/, month).gsub(/\[\[year\]\]/, year).gsub(/\[\[user\]\]/, username)
	
	uri = URI(url)
	response = Net::HTTP.get_response(uri)

	return @bot.say("Failed to get that user's log.") unless response.code == "200" #string
	
	data = Net::HTTP.get(uri)
	data = data.split("\n")
	
	total_length = 0
	lines = Array.new
	
	data.each do |line|
	  line = line[/]\s.+:\s(.+)/]
	  line = $1
	  
	  if line and !line.start_with?("!")
	    total_length = total_length + line.length
		lines << line
	  end  
	end
	
	average_length = total_length / lines.length
    msg = ""
	
	loop do
	  msg = lines[rand(lines.length)]
	  break if msg.length >= average_length #get a random quote at least longer than the average lenght
	end
	
	@bot.say("#{username}: #{msg}")
  end
  
  def log_chat(line)
    case line
		when /:(.+?)!.+PRIVMSG #.+ :(.*)/i
			user = $1
			message = $2
			time = Time.now.to_i
			
			@database.execute("INSERT INTO chatlog(user,time,message) VALUES(?,?,?)", user, time, message)
	end
  end
  
  def register_functions
    register_command('do_log', USER::ALL, 'log')
    register_command('do_random', USER::ALL, 'random')
    register_watcher('log_chat')
  end
end