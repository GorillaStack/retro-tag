require "#{__dir__}/default"

module AwsResource
  class IamUser < Default

    def aws_region_services_name
      %w[IAM]
    end

    def friendly_service_name
      'IAM Users'
    end

    def aws_client(region:,credentials:)
      Aws::IAM::Client.new(region: region, credentials: credentials)
    end

    def aws_client_method
      'list_users'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'users'
    end

    def aws_response_resource_name
      'user_name'
    end

    def aws_event_name
      %w[CreateUser]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['user'] &&
        args[:response_elements]['user']['userName'])
    end

    def resource_name(**args)
      args[:response_elements]['user']['userName']
    end

  end

end
