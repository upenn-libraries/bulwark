module MessengerClient

  def client
    Messenger.new(Bunny.config['host'])
  end

  module_function :client
end
