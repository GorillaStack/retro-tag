require "#{__dir__}/default"

module AwsResource
  class S3Bucket < Default

    def aws_region_services_name
      %w[S3]
    end

    def friendly_service_name
      'S3 Buckets'
    end

    def aws_client(region:)
      Aws::S3::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'list_buckets'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'buckets'
    end

    def aws_response_resource_name
      'name'
    end

    def aws_event_name
      %w[CreateBucket]
    end

    def resource_name_exists?(**args)
      (args[:request_parameters]['bucketName'])
    end

    def resource_name(**args)
      args[:request_parameters]['bucketName']
    end

    ##################################

    def aws_region_helper(resource_id:, region:)
      get_bucket_location = client.get_bucket_location(bucket: resource_id)

      bucket_region = get_bucket_location.location_constraint.empty? ? 'us-east-1' : get_bucket_location.location_constraint
      bucket_region = 'eu-west-1' if bucket_region == 'EU'
      bucket_region ? bucket_region : region.name
    end

  end

end
