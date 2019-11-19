require "#{__dir__}/default"

module AwsResource
  class CloudWatchEventsRule < Default

    def aws_region_services_name
      %w[CloudWatchEvents]
    end

    def friendly_service_name
      'CloudWatch Events Rules'
    end

    def aws_client(region:)
      Aws::CloudWatchEvents::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'list_rules'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'rules'
    end

    def aws_response_resource_name
      'arn'
    end

    def aws_event_name
      %w[PutRule]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['ruleArn'])
    end

    def resource_name(**args)
      args[:response_elements]['ruleArn']
    end

  end
end
