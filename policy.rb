require "base64"
require "digest/sha1"
require "json"
require "openssl"
require "time"

module Policy
  MAX_SIZE = 256 * 1024 * 1024 # 256 MB

  def self.generate(
    namespace: "/",
    bucket: ENV["AWS_BUCKET"],
    max_size: MAX_SIZE,
    expiration: "#{(Date.today + 7).iso8601}T12:00:00.000Z",
    access_key_id: ENV["AWS_ACCESS_KEY_ID"],
    secret_key: ENV["AWS_SECRET_KEY"]
  )
    policy_document = {
      expiration: expiration,
      conditions: [
        { acl: "public-read"},
        { bucket: bucket},
        ["starts-with", "$key", namespace],
        ["starts-with", "$Cache-Control", "max-age="],
        ["starts-with", "$Content-Type", ""],
        ["content-length-range", 0, max_size]
      ]
    }.to_json

    encoded_policy_document = Base64.encode64(policy_document).gsub("\n","")

    {
      accessKey: access_key_id,
      policy: encoded_policy_document,
      signature: sign_policy(encoded_policy_document, secret_key)
    }.to_json
  end

  def self.sign_policy(base64_encoded_policy_document, aws_secret_key)
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        aws_secret_key,
        base64_encoded_policy_document
      )
    ).gsub("\n","")
  end
end
