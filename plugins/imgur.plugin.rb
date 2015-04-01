class Imgur < Plugin
   
  def initialize(bot)
    super(bot)
    @database = open_database('imgur')
    @database.execute("CREATE TABLE IF NOT EXISTS 'images' (code TEXT PRIMARY KEY, url TEXT, added_by TEXT);")
  end
  
  def parse_images(line)
    case line
     when /:(.+?)!.+PRIVMSG\s#.+\s:.*((?:https?:\/\/)?(?:i.)?imgur.com\/((?:(?:gallery|a)\/)?\w*)(?:\.[a-z]{3})?)/i
       url = $2
       code = $3
       user = $1
       add_image(code, url, user)       
     end
  end
  
  def add_image(code, url, user)
    begin
      @database.execute("INSERT INTO 'images' VALUES (?, ?, ?);", code, url, user)
      log "added image: #{url}" if CONFIG::DEBUG && @database.changes > 0
    rescue SQLite3::ConstraintException
      log "#{url} was not added" if CONFIG::DEBUG
    end
    
  end
  
  def random_image(user, args)
    image = @database.execute("SELECT url FROM 'images' ORDER BY RANDOM() LIMIT 1;")
    return if image.nil?
    image = image.first["url"]
    image = "http://#{image}" unless image[0..6] == "http://"
    @bot.say(image)
  end
  
  def register_functions
    register_watcher('parse_images')
    register_command('random_image', USER::ALL, 'randomimage')
  end
end