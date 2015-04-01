require './bot'
require 'yaml'

channels = ARGV.map{|chan| "##{chan}"}

bots = Set.new

if !File.exists?('./PIDS')
  File.open('./PIDS', 'w') { |f| f.puts Hash.new.to_yaml }
end

pids = YAML.load_file('./PIDS')

channels.each do |channel|
  if pids.has_key?(channel)
    puts "There is already a bot running in #{channel} (PID: #{pids[channel]})"
    next
  end
  
  bot = Bot.new(channel)
  bots << bot
  puts "Bot created for #{channel}" unless bot.nil?
  puts "Bot could not be created for #{channel}" if bot.nil?
end

bots.each do |bot|
  pids[bot.channel] = fork do
    bot.start
  end
  puts "Bot started in #{bot.channel}"
  Process.detach(pids[bot.channel])
end

puts pids.inspect

File.open('./PIDS', 'w') { |f| f.puts pids.to_yaml }