# require 'aws-sdk'
require 'json'
require 'csv'
require 'yaml'

require "#{__dir__}/../auto_tag/aws_mixin.rb"

module AwsResource
  class Default

    attr_accessor :csv,
                  :client,
                  :profile,
                  :resource,
                  :bucket_name,
                  :credentials,
                  :results_bad,
                  :results_good,
                  :files_cached,
                  :bucket_region,
                  :cloudtrail_s3,
                  :cloudtrail_s3_keys,
                  :client_retry_limit,
                  :existing_resources

    def initialize(csv:, credentials:, bucket_name:, profile:)
      @csv           = csv
      @credentials   = credentials
      @bucket_name   = bucket_name
      @bucket_region = bucket_region
      @profile       = profile
      @files_cached  = false
      @existing_resources = {}
      @cloudtrail_s3_keys = []
      @cloudtrail_s3      = {}

      @auto_tag_prefix = 'AutoTag_'
      @results_good    = []
      @results_bad     = []

      @client_retry_limit = 8
    end

    include AwsMixin

    def get_resources

      if aws_region_services_name.include? 'IAM'
        regions = Aws.partition('aws').regions.select { |region| region.name == 'us-east-1' }
      else
        regions = Aws.partition('aws').regions.
          select { |region| region.services.any? { |region| aws_region_services_name.include? region } }
      end

      regions.each do |region|
        next unless region.name == 'us-east-1' if friendly_service_name == 'S3 Buckets'
        safe_puts "Collecting resources from #{friendly_service_name} in #{region.name}" if $args['--details']
        @client = aws_client(region: region.name)

        begin
          client.send(aws_client_method, **aws_client_method_args).each do |describe|
            describe.send(aws_response_collection).each do |resource|
              resource_id = resource.is_a?(String) ? resource : resource.send(aws_response_resource_name)
              resource_id = resource_id_helper(resource_id: resource_id, region: region.name)
              aws_region  = aws_region_helper(resource_id: resource_id, region: region.name)

              @existing_resources[resource_id] = {
                region: aws_region,
                tags: []
              }
            end
          end
        rescue Aws::EC2::Errors::AuthFailure, Aws::EMR::Errors::UnrecognizedClientException,
          Aws::ElasticLoadBalancingV2::Errors::InvalidClientTokenId, Aws::RDS::Errors::InvalidClientTokenId,
          Aws::DynamoDB::Errors::UnrecognizedClientException, Aws::ElasticLoadBalancing::Errors::InvalidClientTokenId,
          Aws::AutoScaling::Errors::InvalidClientTokenId, Aws::S3::Errors::InvalidAccessKeyId
          puts "Error: Skipping disabled region #{region.name}..."
          next
        end
      end

      @files_cached = true
    end

    def resource_id_helper(resource_id:, region:)
      resource_id
    end

    def aws_region_helper(resource_id:, region:)
      region
    end

    def process_cloudtrail_event(event:)
      event_name = event['eventName']
      s3_path    = event['key']
      response_elements  = JSON.parse(event['responseElements'])
      response_elements  = response_elements.nil? ? {} : response_elements
      request_parameters = JSON.parse(event['requestParameters'])
      request_parameters = request_parameters.nil? ? {} : request_parameters
      options = {
          # event_time:       event['eventtime']
          # event_source:     event['eventsource']
          event_name:         event_name,
          s3_path:            s3_path,
          aws_region:         event['awsRegion'],
          response_elements:  response_elements,
          request_parameters: request_parameters
      }
      if event['recipientAccountId']
        options[:aws_account_id] = event['recipientAccountId']
      else
        options[:aws_account_id] = event['userIdentity.accountId']
      end
      if aws_event_name.include? event_name
        if resource_name_exists?(options)
          event_resource_name = resource_name(options)
        end

        if existing_resources.has_key? event_resource_name
          # @cloudtrail_s3_keys << s3_path.sub("s3://#{bucket_name}/", '')
          @cloudtrail_s3["#{event_name}_#{event_resource_name}"] = s3_path.sub("s3://#{bucket_name}/", '')
          return true
        end
      end

      false
    end

    def self.s3_object_event(bucket, region, key)
      { Records: [{
         eventVersion: '2.0',
         eventSource: 'aws:s3',
         awsRegion: region,
         eventName: 'ObjectCreated:Put',
         s3: {
           s3SchemaVersion: '1.0',
           bucket: {
             name: bucket
           },
           object: {
             key: key
           }
         }
        }]
      }
    end
  end
end

class Object
  def send_chain(methods)
    methods.inject(self) do |obj, method|
      obj.send method
    end
  end

  def safe_puts(msg)
    puts msg + "\n"
  end
end

class Humanize
  def self.int(int)
    if decimals(int).zero?
      int.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
    else
      int.round(1).to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
    end
  end

  def self.decimals(a)
    num = 0
    while(a != a.to_i)
      num += 1
      a *= 10
    end
    num
  end

  def self.time(secs)
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map do |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    end.compact.reverse.join(' ')
  end
end
