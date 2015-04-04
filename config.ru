require './app'

use Rack::Session::Cookie,
  expire_after: 315360000,
  secret: ENV['SESSION_SECRET']

run Sinatra::Application
