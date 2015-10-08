require 'faye/websocket'
require "sinatra/activerecord"

class Pubsub
  KEEPALIVE_TIME = 15 # in seconds

  def initialize(app)
    @app     = app
    @clients = []
    @channel = "websockets"

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute "LISTEN #{@channel}"

        begin
          loop do
            connection.raw_connection.wait_for_notify(0.5) do |channel, pid, payload|
              @clients.each do |ws|
                ws.send(payload)
              end
            end
          end
        ensure
          connection.execute "UNLISTEN *"
        end
      end
    end
  end

  def notify(payload)
    puts "Notify: #{payload}"
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      sql = "NOTIFY #{@channel}, #{connection.quote(payload)}"
      puts sql
      connection.execute sql
    end
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

      ws.on :open do |event|
        p [:open, ws.object_id]
        @clients << ws
      end

      ws.on :message do |event|
        p [:message, event.data]
        self.notify event.data
      end

      ws.on :close do |event|
        p [:close, ws.object_id, event.code, event.reason]
        @clients.delete(ws)
        ws = nil
      end

      ws.rack_response
    else
      @app.call(env)
    end
  end
end
