require 'securerandom'
require 'sequel'

Sequel.connect(ENV['DATABASE_URL'])

class Person < Sequel::Model
  def before_create
    self.persistent_token = SecureRandom.uuid
    super
  end
end
