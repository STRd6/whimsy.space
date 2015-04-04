require "rack/cors"

use Rack::Cors do |config|
  config.allow do |allow|
    allow.origins '*'
    allow.resource '*',
      :headers => :any
  end
end
