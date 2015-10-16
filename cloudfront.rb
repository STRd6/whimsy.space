require "aws-sdk"

module CloudFront
  def self.create_subdomain(domain)
    res = self.create_distribution(domain)
    cloudfront_domain = res.distribution.domain_name
    self.create_dns(domain, cloudfront_domain)
  end

  def self.create_dns(domain, cloudfront_domain)
    route53 = Aws::Route53::Client.new(
      credentials: Aws::Credentials.new(ENV["AWS_DOMAIN_ACCESS_KEY"], ENV["AWS_DOMAIN_SECRET_KEY"]),
      region: 'us-east-1'
    )

    route53.change_resource_record_sets({
      hosted_zone_id: "Z37HC4BHZ115H3",
      change_batch: {
        comment: "ResourceDescription",
        changes: [{
          action: "CREATE",
          resource_record_set: {
            name: "#{domain}.whimsy.space",
            type: "A",
            alias_target: {
              hosted_zone_id: "Z2FDTNDATAQYW2", # Special Zone ID for CloudFront Distributions
              dns_name: cloudfront_domain,
              evaluate_target_health: false
            }
          }
        }]
      }
    })
  end

  def self.create_distribution(domain)
    cname = "#{domain}.whimsy.space"
    ref = Time.now.to_i.to_s
    origin_id = "S3-whimsyspace-databucket-1g3p6d9lcl6x1/#{domain}"

    cloudfront = Aws::CloudFront::Client.new(
      credentials: Aws::Credentials.new(ENV["AWS_DOMAIN_ACCESS_KEY"], ENV["AWS_DOMAIN_SECRET_KEY"]),
      region: 'us-east-1'
    )

    cloudfront.create_distribution({
      :distribution_config => {
        :caller_reference => ref,
        :aliases => {
          :quantity => 1,
          :items => [cname]
        },
        :default_root_object => "index.html",
        :origins => {
          :quantity => 1,
          :items => [
            :id => origin_id,
            :domain_name => "whimsyspace-databucket-1g3p6d9lcl6x1.s3.amazonaws.com",
            :origin_path => "/#{domain}",
            :s3_origin_config => {
              :origin_access_identity => ""
            }
          ]
        },
        :default_cache_behavior => {
          :target_origin_id => origin_id,
          :forwarded_values => {
            :query_string => false,
            :cookies => {
              :forward => "none"
            },
            :headers => {
              :quantity => 3,
              :items => [
                "Origin",
                "Access-Control-Request-Headers",
                "Access-Control-Request-Method"
              ]
            }
          },
          :trusted_signers => {
            :enabled => false,
            :quantity => 0
          },
          :viewer_protocol_policy => "allow-all",
          :min_ttl => 0,
          :allowed_methods => {
            :quantity => 3,
            :items => [
              "GET",
              "HEAD",
              "OPTIONS"
            ]
          }
        },
        :comment => cname,
        :logging => {
          :enabled => true,
          :include_cookies => false,
          :bucket => "whimsyspace-logbucket-180k2va5nggex.s3.amazonaws.com",
          :prefix => cname
        },
        :enabled => true
      }
    })
  end

end
