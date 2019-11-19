require "#{__dir__}/default"

module AwsResource
  class CloudWatchAlarm < Default

    def aws_region_services_name
      %w[CloudWatch]
    end

    def friendly_service_name
      'CloudWatch Alarms'
    end

    def aws_client(region:)
      Aws::CloudWatch::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'describe_alarms'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'metric_alarms'
    end

    def aws_response_resource_name
      'alarm_arn'
    end

    def aws_event_name
      %w[PutMetricAlarm]
    end

    def resource_name_exists?(**args)
      (arn_builder(args))
    end

    def resource_name(**args)
      arn_builder(args)
    end

    def arn_builder(**args)
      arn_builder = %w(arn aws cloudwatch)
      arn_builder.push args[:aws_region]
      arn_builder.push args[:aws_account_id]
      arn_builder.push 'alarm'
      arn_builder.push args[:request_parameters]['alarmName']
      arn_builder.join(':')
    end

  end
end
