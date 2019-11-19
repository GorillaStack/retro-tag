require "#{__dir__}/default"

module AwsResource
  class Ec2DhcpOptions < Default

    def aws_region_services_name
      %w[EC2]
    end

    def friendly_service_name
      'EC2 DHCP Options Sets'
    end

    def aws_client(region:)
      Aws::EC2::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'describe_dhcp_options'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'dhcp_options'
    end

    def aws_response_resource_name
      'dhcp_options_id'
    end

    def aws_event_name
      %w[CreateDhcpOptions]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['dhcpOptions'] &&
       args[:response_elements]['dhcpOptions']['dhcpOptionsId'])
    end

    def resource_name(**args)
      args[:response_elements]['dhcpOptions']['dhcpOptionsId']
    end

  end

end
