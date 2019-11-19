require "#{__dir__}/default"

module AwsResource
  class Ec2CustomerGateway < Default

    def aws_region_services_name
      %w[EC2]
    end

    def friendly_service_name
      'EC2 Customer Gateways'
    end

    def aws_client(region:)
      Aws::EC2::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'describe_customer_gateways'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'customer_gateways'
    end

    def aws_response_resource_name
      'customer_gateway_id'
    end

    def aws_event_name
      %w[CreateCustomerGateway]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['customerGateway'] &&
       args[:response_elements]['customerGateway']['customerGatewayId'])
    end

    def resource_name(**args)
      args[:response_elements]['customerGateway']['customerGatewayId']
    end

  end

end
