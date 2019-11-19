# require 'aws-sdk'
require 'yaml'

require "#{__dir__}/../auto_tag/aws_mixin.rb"

module AwsTag
  class Default

    attr_accessor :credentials, :auto_tag_prefix, :existing_tags, :existing_resources, :auto_tags_view, :results_good, :results_bad, :client_retry_limit

    def initialize(credentials:)
      @credentials     = credentials
      @auto_tag_prefix = 'AutoTag_'
      @existing_tags   = []
      @results_good    = []
      @results_bad     = []

      @client_retry_limit = 8
    end

    include AwsMixin

    def get_tags

      if aws_region_services_name.include? 'IAM'
        regions = Aws.partition('aws').regions.select { |region| region.name == 'us-east-1' }
      else
        regions = Aws.partition('aws').regions.
          select { |region| region.services.any? { |r| aws_region_services_name.include? r } }
      end

      regions.each do |region|
        safe_puts "Collecting tags from #{friendly_service_name} in #{region.name}" if $args['--details']
        client = aws_client(region: region.name)
        begin
          tags_client(client: client, region: region.name)
        rescue Aws::EC2::Errors::AuthFailure, Aws::EMR::Errors::UnrecognizedClientException,
          Aws::ElasticLoadBalancingV2::Errors::InvalidClientTokenId, Aws::RDS::Errors::InvalidClientTokenId,
          Aws::DynamoDB::Errors::UnrecognizedClientException, Aws::ElasticLoadBalancing::Errors::InvalidClientTokenId,
          Aws::AutoScaling::Errors::InvalidClientTokenId, Aws::S3::Errors::InvalidAccessKeyId,
          Aws::Lambda::Errors::UnrecognizedClientException, Aws::CloudWatch::Errors::InvalidClientTokenId,
          Aws::CloudWatchLogs::Errors::UnrecognizedClientException, Aws::CloudWatchEvents::Errors::UnrecognizedClientException
          puts "Error: Skipping disabled region #{region.name}..."
          next
        end
      end
    end

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)

      client.send(tag_client_method, **og_tag_client_method_args).each do |describe|
        save_tags(describe: describe, region: region)
      end
    end

    def save_tags(describe:, region:, resource_id: nil)
      describe.send_chain(tag_response_collection.split('.')).each do |tag|
        resource_id_final = resource_id ? resource_id : tag[tag_response_resource_name]

        @existing_tags << {
          region:        region,
          resource_id:   resource_id_final,
          key:           tag['key'],
          value:         tag['value'],
          resource_type: friendly_service_name
        }
      end
    end
  end
end


