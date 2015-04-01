require 'set'

class Plugin
  @plugins = Set.new
  
  def initialize(bot)
    @bot = bot  
  end
  
  def self.plugins
    @plugins
  end
  
  def register_command(function, rights = USER::ALL, command = function)
    @bot.register_command(function, command, rights, self)
  end
  
  def register_watcher(function)
    @bot.register_watcher(function, self)
  end
  
  def open_database(name, options={ results_as_hash: true })
    dir = "./data/#{@bot.channel}/"
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    return SQLite3::Database.new("#{dir}#{self.class.name.downcase}_#{name}.db", options)
  end
  
  def self.inherited(subclass)
    @plugins << subclass
  end
end