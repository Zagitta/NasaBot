module Filter
  def filter(message)
    message = message.strip
    message = message[/[^!.\/].*/]
    return message
  end
end