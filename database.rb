require 'sequel'

Sequel.connect(ENV['DATABASE_URL'])

class Person < Sequel::Model
end
