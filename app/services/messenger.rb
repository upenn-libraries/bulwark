class Messenger
  
  attr_reader :amqp_host

  def initialize(amqp_host = Bunny.config[:host])
    @amqp_host = amqp_host
  end

  def publish(message)
    exchange.publish(message, persistent: true)
  rescue
    Rails.logger.warn "Could not publish message to #{amqp_host}"
  end

  private

    def bunny_client
      @bunny_client ||= Bunny.new(amqp_host).tap(&:start)
    end

    def channel
      @channel ||= bunny_client.create_channel
    end

    def exchange
      @exchange ||= channel.fanout("colenda", durable: true)
    end
end
