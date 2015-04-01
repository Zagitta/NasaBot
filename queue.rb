require './config'
require './filter'
require 'zlib'

class MessageQueue
  
  include Filter
  
  def initialize(bot)
    @queue = Array.new
    @history_length = 20
    @last_messages = Array.new(@history_length)
    @bot = bot
  end
  
  def add(message, always_show = false)
    checksum = Zlib::crc32(message)
    resize(calc_size(@bot.users.size))
    return if @queue.include?(message) || (@last_messages.include?(checksum) && !always_show) || message.length > @bot.message_length
    
    @queue << filter(message) 
    @last_messages.shift
    @last_messages[@history_length-1] = checksum
    
  end
  
  def clear
    @queue.clear
  end
  
  def resize(size)
    return if size == @last_messages.length
    if @last_messages.length > size
      @last_messages.shift(@last_messages.length - size)
    else
      delta = size - @last_messages.length
      delta.times { @last_messages.unshift(nil) }
    end
    
    @history_length = size
  end
  
  
  def next(max_length)
    length = 0

    sending = @queue.select {|value| (length = length + value.length) &&  length <= max_length}
    sending.each { |value| 
      @queue.delete_at(@queue.index(value))  
    }
    
    return sending
  end
  
  def calc_size(base)
    size = 1 + (Math::log10(base) * Math::log2(base) * 0.3).round
    return size
  end
  
  def size
    return {history_length: @history_length, history_size: @last_messages.size}
  end
end