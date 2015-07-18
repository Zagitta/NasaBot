require './irc'
require './config'
require './plugin'
require './constants'
require 'fileutils'

require 'sqlite3'


class Bot < IRC
  
  def initialize(channel)
    super(CONFIG::SERVER, CONFIG::PORT, CONFIG::USER, CONFIG::PASSWORD, channel)
    @commands = Hash.new
    @watchers = Hash.new
    @scheduled = Hash.new
	
    require "./plugins/profiles/#{channel}.profile.rb"
    Dir["./plugins/*.plugin.rb"].each {|file| require file if PROFILE::PLUGINS.include?(file.partition(/\/plugins\//)[2]) }
	
	update_plugins
  end
  
  def update_plugins
    Object.constants.each do |obj_class|
	  const = Kernel.const_get(obj_class) #get all symbols
	  
	  if const.respond_to?(:superclass) and const.superclass == Plugin #symbol has superclass and superclass == plugin
	    if not Plugin.plugins.include?(const)
		  log "LOADING #{const}" if CONFIG::VERBOSE
		  Plugin.plugins << const #add class to list of active plugins
		  
		  plugin_instance = const.new(self) #instantiate 
		  plugin_instance.register_functions
		end
	  end
	end
  end
  
  def plugin_loaded?(name)
    plugin = Plugin.plugins.detect{|plugin| plugin.to_s.downcase == name}
	
	return plugin ? true : false
  end
  
  def active_plugins()
    array = Array.new
    Plugin.plugins.each do |plugin|
	  array << plugin.to_s.downcase
	end
	
	return array
  end
  
  def load_plugin_file(name)
    file = "./plugins/" + name + ".plugin.rb"	
	return false unless File.exists?(file)
	
	log "LOADING PLUGIN FROM FILE: #{name}", true if CONFIG::VERBOSE
	
	load file
	update_plugins
	
	return true
  end
  
  def unload_plugin(name)
    name = name.downcase
    return false unless plugin_loaded?(name)
	return false if name == "base"
  
    log "UNLOADING PLUGIN: #{name}", true if CONFIG::VERBOSE
	
    commands = @commands.select{|k,v| v[:plugin].class.to_s.downcase == name}

	commands.each do |k,v|
	  unregister_command(v[:function])
	end
  
    watchers = @watchers.select{|k,v| v[:plugin].class.to_s.downcase == name}
	
	watchers.each do |k,v|
	  unregister_watcher(v[:function])
	end
  
    plugin = Plugin.plugins.detect{|plugin| plugin.to_s.downcase == name}
    Plugin.plugins.delete(plugin)
	
	return true
  end
  
  def register_command(function, command, rights, plugin)
    @commands[command] = { function: function, users: rights, plugin: plugin, enabled: true}
    log "REG CMD: #{command} -> #{function}, USERGROUP: #{rights}", true if CONFIG::VERBOSE
  end
  
  def unregister_command(command)
    return false if @commands[command].nil?
  
    log "UNREG CMD: #{command} -> #{@commands[command][:function]}", true if CONFIG::VERBOSE
    @commands.delete(command)
	
	return true
  end
  
  def enable_command(command, flag)
    return false if @commands[command].nil?
  
    log "ENABLE CMD: #{command} -> #{@commands[command][:function]} #{flag}", true if CONFIG::VERBOSE
    @commands[command][:enabled] = flag
	
	return true
  end
  
  def register_scheduled(function)
    
  end
  
  def register_watcher(function, plugin)
    @watchers[function] = {function: function, plugin: plugin, enabled: true}
    log "REG WATCH: #{function}", true if CONFIG::VERBOSE
  end
  
  def enable_watcher(function, flag)
    return false if @watchers[function].nil?
  
    log "ENABLE WATCH: #{function} #{flag}", true if CONFIG::VERBOSE
    @watchers[function][:enabled] = flag 
	
	return true
  end
  
  def unregister_watcher(function)
    return false if @watchers[function].nil?
  
    log "UNREG WATCH: #{function}", true if CONFIG::VERBOSE
    @watchers.delete(function)
	
	return true
  end
  
  def handle_input(line)
    case line
      when /:(.+?)!.+PRIVMSG #.+ :\s*!(\S+)(.*)/i
        user = $1
        command = $2
        args = $3
        function_data = @commands[command]
        if !function_data.nil? && function_data[:enabled]
          log "USER: #{user}, COMMAND: #{command}, ARGUMENTS: #{args}" if CONFIG::VERBOSE
          begin
            function_data[:plugin].send(function_data[:function], user, args) if can_execute?(user, function_data)
          rescue Exception => e
            log e
          end          
        end
      else
        
    end
    
    @watchers.each do |function, watcher|
      watcher[:plugin].send(watcher[:function], line) if watcher[:enabled]
    end
  end
  
  
  def can_execute?(user, function_data)
    required = function_data[:users]
    case required
    when USER::ALL
      return true
    when USER::MODERATOR
      return user_mod?(user)
    when USER::BROADCASTER
      return user_broadcaster?(user)
    else 
      return false
    end
  end
  
  def start
    while true
	self.connect	
		self.send("CAP REQ :twitch.tv/commands")
		self.send("CAP REQ :twitch.tv/membership")
		
		self.read_stream
		self.quit
	end
  end
  
end