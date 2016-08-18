require "bunny"

# Start a communication session with RabbitMQ
conn = Bunny.new
conn.start

# open a channel
ch = conn.create_channel

# declare a queue
q  = ch.queue("regenerate_metadata")

# publish a message to the default exchange which then gets routed to this queue
q.publish("XML built!")

# fetch a message from the queue
delivery_info, metadata, payload = q.pop

puts "This is the message: #{payload}"

# close the connection
conn.stop
