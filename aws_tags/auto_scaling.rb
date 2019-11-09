require "#{__dir__}/default"

module AwsTags
  class AutoScaling < Default

    def aws_region_services_name
      %w[AutoScaling]
    end

    def friendly_service_name
      'AutoScaling Groups'
    end

    def aws_client(region:)
      Aws::AutoScaling::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'describe_tags'
    end

    def tag_client_method_args(region)
      {}
    end

    def tag_response_collection
      'tags'
    end

    def tag_response_resource_name
      'resource_id'
    end

    ##################################

  end

end
