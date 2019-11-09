require "#{__dir__}/default"

module AwsResource
  class ElasticLoadBalancingV2 < Default

    def aws_region_services_name
      %w(ElasticLoadBalancingV2)
    end

    def friendly_service_name
      'Elastic Load Balancing V2'
    end

    def aws_client(region:)
      Aws::ElasticLoadBalancingV2::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'describe_load_balancers'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'load_balancers'
    end

    def aws_response_resource_name
      'load_balancer_arn'
    end

    def aws_event_name
      %w[CreateLoadBalancer]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['loadBalancers'] &&
          args[:response_elements]['loadBalancers'][0] &&
          args[:response_elements]['loadBalancers'][0]['loadBalancerArn'])
    end

    def resource_name(**args)
      args[:response_elements]['loadBalancers'][0]['loadBalancerArn']
    end

  end
end
