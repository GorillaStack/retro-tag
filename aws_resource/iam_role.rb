require "#{__dir__}/default"

module AwsResource
  class IamRole < Default

    def aws_region_services_name
      %w[IAM]
    end

    def friendly_service_name
      'IAM Roles'
    end

    def aws_client(region:,credentials:)
      Aws::IAM::Client.new(region: region, credentials: credentials)
    end

    def aws_client_method
      'list_roles'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'roles'
    end

    def aws_response_resource_name
      'role_name'
    end

    def aws_event_name
      %w[CreateRole]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['role'] &&
        args[:response_elements]['role']['roleName'])
    end

    def resource_name(**args)
      args[:response_elements]['role']['roleName']
    end

  end

end
