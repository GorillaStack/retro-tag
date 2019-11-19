require "#{__dir__}/default"

module AwsResource
  class CloudWatchLogGroup < Default

    def aws_region_services_name
      %w[CloudWatchLogs]
    end

    def friendly_service_name
      'CloudWatch Log Groups'
    end

    def aws_client(region:)
      Aws::CloudWatchLogs::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'describe_log_groups'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'log_groups'
    end

    def aws_response_resource_name
      'log_group_name'
    end

    def aws_event_name
      %w[CreateLogGroup]
    end

    def resource_name_exists?(**args)
      (args[:request_parameters]['logGroupName'])
    end

    def resource_name(**args)
      args[:request_parameters]['logGroupName']
    end

  end
end
