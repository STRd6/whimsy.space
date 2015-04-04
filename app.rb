require 'pry' if ENV["RACK_ENV"] == "development"
require 'sinatra'

require './cors'
require './database'
require './mail'
require './policy'

def person
  @person ||= Person.find(persistent_token: session[:token])
end

before do
  content_type :json
end

get '/hello' do
  Person.count.to_s
end

get '/test_mail' do
  Mail.messages.send subject: "Test",
    from_email: "duder@notifications.whimsy.space",
    from_name: "Duder von Broheim",
    to: [
      name: "Daniel",
      email: "yahivin@gmail.com",
    ],
    text: "What a time to be alive@!"

  "OK"
end

get '/test' do
  binding.pry
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

get '/login/:token' do
  if Person.find(persistent_token: params[:token])
    session[:token] = params[:token]
  else
    status 401
  end
end

post '/login' do
  # Find or create person by email, setting domain if given
  person = Person.find_or_create(email: params[:email]) do |person|
    person.domain = params[:domain]
  end

  # Send email with login link
  Mail.messages.send subject: "Your link to whimsy",
    from_email: "duder@inbound.whimsy.space",
    from_name: "Duder von Broheim",
    to: [
      email: person.email
    ],
    text: "Log in here: #{request.base_url}/login/#{person.persistent_token}"

  "OK"
end
