require './app'
require './pubsub'

require "rack/cors"

use Rack::Cors do |config|
  config.allow do |allow|
    allow.origins '*'
    allow.resource '*',
      :headers => :any
  end
end

use Rack::Session::Cookie,
  expire_after: 315360000,
  secret: ENV['SESSION_SECRET']

use Pubsub

run Sinatra::Application
