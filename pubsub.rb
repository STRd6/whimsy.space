require 'faye/websocket'
require './database'
require 'ostruct'
require 'aws-sdk'

class Pubsub
  KEEPALIVE_TIME = 15 # in seconds

  def initialize(app)
    @app     = app
    @clients = []
    @channel = "websockets"
    @save_domains = Hash.new(0)

    # S3 Publish Thread
    Thread.new do
      s3 = Aws::S3::Resource.new(region: "us-east-1")

      ActiveRecord::Base.connection_pool.with_connection do |connection|
        begin
          loop do
            started = Time.now

            @save_domains.each do |domain, value|
              if value > 0
                @save_domains[domain] = 0
                # Read FS and post to S3
                person = Person.find_by_domain(domain)

                p [:uploading, domain]

                object = s3.bucket(ENV["AWS_BUCKET"]).object("#{domain}/index.json")
                object.put(
                  content_type: "application/json",
                  cache_control: "max-age=0",
                  body: JSON.generate(files: person.filesystem)
                )
              end
            end

            finished = Time.now
            duration = finished - started
            if duration < 5
              sleep 5 - duration
            end
          end
        ensure
        end
      end
    end

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute "LISTEN #{@channel}"

        begin
          loop do
            connection.raw_connection.wait_for_notify(0.5) do |channel, pid, payload|
              message = JSON.parse(payload)

              @clients.each do |client|
                if client.space == message["space"]
                  client.ws.send(JSON.generate(
                    type: message["type"],
                    data: message["data"]
                  ))
                end
              end
            end
          end
        ensure
          connection.execute "UNLISTEN *"
        end
      end
    end
  end

  def notify(data)
    puts "Notify: #{data}"
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      sql = "NOTIFY #{@channel}, #{connection.quote(JSON.generate(data))}"
      puts sql
      connection.execute sql
    end
  end

  def send_error_message(ws, msg)
    ws.send(JSON.generate(error: msg))
  end

  def fs_find(fs, path)
    fs.select do |file|
      file["path"] == path
    end.first
  end

  def fs_rename(fs, oldPath, newPath)
    file = fs_find(fs, oldPath)

    file["path"] = newPath
  end

  def fs_write(fs, data)
    file = fs_find(fs, data["path"])

    if file
      file.merge! data
    else
      fs.push data
    end
  end

  def fs_remove(fs, data)
    fs.select! do |file|
      file["path"] != data["path"]
    end
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

      conn = OpenStruct.new
      conn.ws = ws

      ws.on :open do |event|
        p [:open, ws.object_id]
        @clients << conn
      end

      ws.on :message do |event|
        begin
          message = JSON.parse(event.data)

          p message

          # Handle initialization
          if message["init"]
            conn.space = message["space"]
            conn.token = message["token"]
          else # Receive FS change event
            # Validate token
            person = Person.select("domain").find_by_persistent_token(conn.token)

            unless person
              self.send_error_message(ws, "Couldn't find user by token")
              next
            end

            if person.domain == conn.space
              # Write fs in db
              ActiveRecord::Base.transaction do
                # Read FS
                person = Person.find_by_persistent_token(conn.token)
                filesystem = person.filesystem

                puts filesystem

                # Modify
                case message["type"]
                when "write"
                  self.fs_write(filesystem, *message["data"])
                when "remove"
                  self.fs_remove(filesystem, *message["data"])
                when "rename"
                  self.fs_rename(filesystem, *message["data"])
                when "overwrite"
                  filesystem = message["data"]
                  message["data"] = {}
                  message["type"] = "reload"
                end

                p filesystem
                person.filesystem = filesystem
                # Save
                person.save!

                # Schedule job to write to S3
                @save_domains[conn.space] += 1
              end

              # Broadcast change to all listeners on the same channel
              self.notify(
                space: conn.space,
                data: message["data"],
                type: message["type"]
              )
            else
              # Ignore event, token doesn't match
              self.send_error_message(ws, "Token doesn't match domain")
            end
          end
        rescue Exception => e
          puts e
        end
      end

      ws.on :close do |event|
        p [:close, ws.object_id, event.code, event.reason]
        @clients.delete(conn)
        conn.ws = ws = nil
      end

      ws.rack_response
    else
      @app.call(env)
    end
  end
end
