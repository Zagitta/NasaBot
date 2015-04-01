require './bot'

channels = ARGV.map{|chan| "##{chan}"}

channel = channels[0]

bot = Bot.new(channel)

puts "Bot created for #{channel}" unless bot.nil?
puts "Bot could not be created for #{channel}" if bot.nil?

bot.start