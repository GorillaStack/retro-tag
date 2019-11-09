require "#{__dir__}/default"

module AwsResource
  class ElasticLoadBalancing < Default

    def aws_region_services_name
      %w(ElasticLoadBalancing)
    end

    def friendly_service_name
      'Elastic Load Balancing'
    end

    def aws_client(region:)
      Aws::ElasticLoadBalancing::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'describe_load_balancers'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'load_balancer_descriptions'
    end

    def aws_response_resource_name
      'load_balancer_name'
    end

    def aws_event_name
      %w[CreateLoadBalancer]
    end

    def resource_name_exists?(**args)
      (args[:request_parameters]['loadBalancerName'])
    end

    def resource_name(**args)
      args[:request_parameters]['loadBalancerName']
    end

  end
end
