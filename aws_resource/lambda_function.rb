require "#{__dir__}/default"

module AwsResource
  class LambdaFunction < Default

    def aws_region_services_name
      %w[Lambda]
    end

    def friendly_service_name
      'Lambda Functions'
    end

    def aws_client(region:)
      Aws::Lambda::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'list_functions'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'functions'
    end

    def aws_response_resource_name
      'function_arn'
    end

    def aws_event_name
      %w[CreateFunction20150331 CreateFunction20141111]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['functionArn'])
    end

    def resource_name(**args)
      args[:response_elements]['functionArn']
    end

  end

end
