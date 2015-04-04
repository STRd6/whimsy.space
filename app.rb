require 'pry' if ENV["RACK_ENV"] == "development"
require 'sinatra'

require './database'

get '/hello' do
  Person.count.to_s
end
