require 'socket'
require 'set'
require 'time'
require './queue.rb'

class IRC 
  def initialize(server, port, nick, password, channel)
    @logfile = File.open(CONFIG::LOGFILE % channel, "a+")
    @server = server
    @port = port
    @nick = nick
    @password = password
    @channel = channel
    @users = Set.new
    @moderators = Set.new
    @message_queue = MessageQueue.new(self)
    @running = false
    @message_length = CONFIG::MESSAGEMAXLENGTH
  end
  
  def connect
    @running = true
    @socket = TCPSocket.open(@server, @port)
    send "PASS #{@password}", true
    send "NICK #{@nick}"
    send "JOIN #{@channel}"
  end
  
  def quit
    send "QUIT"
    @socket.close
  end
  
  def send(message, mute = false)
    @socket.send "#{message}\n", 0
    log "SENDING: #{message}", true if CONFIG::VERBOSE && !mute
  end
  
  def say(message, show = false)
	log "Queuing message: #{message}"
    @message_queue.add(message, show)    
  end
  
  def say_raw(message)
    send "PRIVMSG #{@channel} :#{CONFIG::MESSAGEPREFIX}#{message}"
  end
  
  def send_message_queue       
	begin
	    to_send = @message_queue.next(@message_length)  

		return if to_send.empty?
		sending = to_send.join(CONFIG::MESSAGEDELIMITER)
		
		send "PRIVMSG #{@channel} :#{CONFIG::MESSAGEPREFIX}#{sending}"
	rescue => error
		log error
	end
  end
  
  def read_stream
    Signal.trap("HUP") { @running = false } unless (RUBY_PLATFORM =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/) != nil 
    messages = Thread.new {
      while @running
        sleep(CONFIG::MESSAGEDELAY)
        send_message_queue       
      end
    }
    begin
      while (line = @socket.readline) && @running
        irc_handle line
      end
    rescue => error
      log error
    end
    #quit
    exit
    
  end
  
  def irc_handle line   
    log line if CONFIG::DEBUG
    
    case line.strip
      when /^PING :?(.+)$/i
        log "SERVER PING"
        send "PONG :#{$1}"
        
      when /^:jtv MODE #.+ (\+|-)o (.+)$/i
        handle_mod($2, $1)
        
      when /:\w*\.?\w*\.\w* \d{3} .+ :-?\s?(.+?)\s?-?$/i
        log "SERVER: #{$1}" if CONFIG::VERBOSE
        
      when /^:.+353.*=\s#.+\s:(.+)/i
        handle_userlist($1)
        
      when /^:(.+)!.+(JOIN|PART)\s#.+/i
        handle_user($1, $2)
      
      when /^:(.+?)!.+PRIVMSG #{@nick} :(.*)/i
        log "#{$1}: #{$2}", true if CONFIG::VERBOSE
        
      else
        handle_input line       
    end
  end
  
  def user_mod?(user)
    @moderators.include?(user) || CONFIG::ADMINS.include?(user)
  end
  
  def user_broadcaster?(user)
    user == @channel[1..-1] || CONFIG::ADMINS.include?(user)
  end
    
  def handle_user(user, type)
    if type == "JOIN"
       @users << user
     elsif type == "PART"
       @users.delete(user)
    end    
  end
  
  def handle_mod(user, type)
    if type == '+'
      @moderators << user
    elsif type == '-'
      @moderators.delete(user)
    end    
  end
  
  def handle_userlist(userlist)
    log " [ USERLIST ]"
    users = userlist.split(" ")
    users.each do |user|
      @users << user.strip
    end   
  end
  
  def log(message, tab = false)
    begin
      message = CONFIG::DEBUG ? message : message[0..CONFIG::LOGTRUNCATE]
      message = " #{message}" if tab
	  puts message if CONFIG::DEBUG
      @logfile.write("#{message}\n")
      @logfile.flush
    rescue
      
    end
      
  end
  
  def moderators
    @moderators
  end
  
  def users
    @users
  end
  
  def channel
    return @channel
  end
  
  def message_length
    @message_length
  end
  
  def message_length=(length)
    @message_length = length
  end
  
  def message_queue
    @message_queue
  end
end