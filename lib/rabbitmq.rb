class BunnyEmitter

  def initialize(server_ip, queue_name)
    @connection = Bunny.new(server_ip)
    @connection.start
    @channel = @connection.create_channel
    @exchange = @channel.default_exchange
    @queue = @channel.queue(queue_name)
  end

  def publish(message)
    @exchange.publish(message, :routing_key => @queue.name)
    puts "[X] Sent: #{message}"
  end

  def close
    @connection.close
    @channel.close
  end
end