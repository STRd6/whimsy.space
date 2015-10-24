require 'pry' if ENV["RACK_ENV"] == "development"
require 'sinatra'
require "sinatra/json"

require './cors'
require './database'
require './mail'
require './policy'

def person
  token = env['HTTP_AUTHORIZATION'] || session[:token]

  @person ||= Person.find_by_persistent_token(token)
end

before do
  content_type :json
end

get '/policy.json' do
  if person
    Policy.generate(
      namespace: "#{person.domain}/"
    )
  else
    status 401
  end
end

post '/register' do
  # Find or create person by email, setting domain if given
  person = Person.find_or_create_by(email: params[:email]) do |person|
    if person.new_record?
      person.domain = params[:domain]
    end
  end

  if person.persisted?
    person.set_up_subdomain

    # Send email with login link
    res = Mail.messages.send subject: "Your link to whimsy",
      from_email: "duder@inbound.whimsy.space",
      from_name: "Duder von Broheim",
      to: [
        email: person.email
      ],
      text: "Your ticket to Whimsy: #{person.persistent_token}"

    if res[0]["status"] == "sent"
      "Check your email"
    else
      status 500
      "Error with yo email perhapms-? #{person.email}"
    end
  else
    status 418
    "Some kind of error #{person.errors.full_messages}"
  end
end
