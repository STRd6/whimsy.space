require 'securerandom'
require "sinatra/activerecord"

require './cloudfront'

class Person < ActiveRecord::Base
  self.primary_key = :persistent_token

  validates_presence_of :email
  validates_presence_of :domain
  validates_presence_of :persistent_token

  validates_format_of :domain, with: /\A[a-z0-9][a-z0-9-]{2,31}\z/
  validates :domain,
    exclusion: {
      in: %w[api blog data www] ,
      message: "%{value} is reserved"
    }

  before_validation(on: :create) do
    ensure_token
    normalize_domain
  end

  def normalize_domain
    self.domain.downcase!
  end

  def ensure_token
    self.persistent_token = SecureRandom.uuid
  end

  def set_up_subdomain
    begin
      CloudFront.create_subdomain(domain)
    rescue Aws::CloudFront::Errors::CNAMEAlreadyExists => e
      # Assuming everything is fine
      # TODO: Check dns?
      return :exists
    end
  end
end
