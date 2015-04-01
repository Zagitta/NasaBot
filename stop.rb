require 'yaml'

channels = ARGV.map{|chan| "##{chan}"}

pids = YAML.load_file('./PIDS')

channels.each do |channel|
  if !pids.has_key?(channel)
    puts "There is no bot running in #{channel}"
    next
  end
  
  begin
    Process.kill("HUP", pids[channel])
    puts "Bot stopped for #{channel}"
  rescue
    puts "There seems to be no process running for #{channel}. Removing from PIDS"
  ensure
    pids.delete(channel)
  end
  
  
  
end

puts pids.inspect

File.open('./PIDS', 'w') { |f| f.puts pids.to_yaml }