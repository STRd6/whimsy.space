require './app'
require './pubsub'

use Rack::Session::Cookie,
  expire_after: 315360000,
  secret: ENV['SESSION_SECRET']

use Pubsub

run Sinatra::Application
